module TetrominoGame exposing
    ( ActionWithTime
    , Connection
    , GameModel
    , GameMsg(..)
    , LiveMatch
    , LocalChange(..)
    , MatchProgress(..)
    , SetupModel
    , SetupMsg(..)
    , SetupOrGame(..)
    , StartingState(..)
    , ToBackend(..)
    , ToFrontend(..)
    , ValidatedSetup
    , Watcher
    , animationFrame
    , canvasId
    , dropMatchState
    , gameView
    , initGame
    , initLiveMatch
    , initSetup
    , matchState
    , matchStateAt
    , pressedKey
    , pruneInputs
    , setupView
    , snapshotFrame
    , stampInput
    , updateFromBackend
    , updateGame
    , updateSetup
    )

{-| The tetromino fort game: the part that at-chat's game framework talks to. The rules live in
`TetrominoSim` and the drawing in `TetrominoView`.

The match only exists on the clients that have it open. The backend passes inputs between them,
stamping each with the time it arrived (`stampInput` keeps that stamp inside the window the server
allows), and every client runs the same simulation over them. Someone opening a match gets its
state from one of the players who already has it open, the way snowball-fight-attempt-2 does it,
and once nobody has it open the match is over.

-}

import Bytes exposing (Bytes)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Lamdera exposing (ClientId)
import Effect.Time as Time
import Effect.WebGL as WebGL
import Go
import Html
import Html.Attributes
import Html.Events
import Id exposing (Id, UserId)
import Json.Decode
import MyUi
import Quantity
import SeqDict exposing (SeqDict)
import SeqSet
import Tetromino exposing (Orientation, Shape)
import TetrominoSim exposing (PieceCycle(..))
import TetrominoTimeline exposing (Timeline)
import TetrominoView exposing (Cursor)
import TetrominoWire
import Ui exposing (Element)
import Ui.Font
import Ui.Prose
import User exposing (LocalUser)
import UserColor exposing (UserColor)


type alias ValidatedSetup =
    { createdBy : Id UserId
    , -- The backend's clock when the match started. Frame numbers are counted from here, so
      -- every client has to agree on it.
      startedAt : Time.Posix
    }


{-| A match ends once nobody has it open, since then nobody has its state any more.
-}
type MatchProgress
    = MatchInProgress
    | MatchEnded


type alias ActionWithTime =
    { userId : Id UserId, time : Time.Posix, input : TetrominoSim.Input }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup


type ToBackend
    = OpenedMatch
    | ClosedMatch
      -- The Int lets the client match up the backend's answer with the input it guessed at.
    | SendInput Int Time.Posix TetrominoSim.Input
      -- The state of the match at the start of a frame the backend asked for, for someone who
      -- has just opened it.
    | CurrentState Int Bytes


type ToFrontend
    = StateRequest Int
    | JoinedMatch
        { frame : Int
        , startingState : StartingState
        , inputs : List ActionWithTime
        , serverTime : Time.Posix
        }
    | InputBroadcast ActionWithTime
      -- One of this client's own inputs, with the time the backend settled on for it.
    | InputAccepted Int ActionWithTime
    | MatchOver


type StartingState
    = FreshMatch
    | FromAnotherPlayer Bytes


{-| What the backend keeps about a match while anyone has it open.
-}
type alias LiveMatch =
    { watchers : SeqDict ClientId Watcher
    , -- Oldest first. Kept for as long as someone joining might still need them.
      recentInputs : List ActionWithTime
    }


{-| A client with the match open. `waitingForFrame` is set until another player has sent the
state the match was in at the start of that frame.
-}
type alias Watcher =
    { userId : Id UserId, waitingForFrame : Maybe Int }


type alias SetupModel =
    {}


type SetupMsg
    = PressedStartGame
    | PressedCancel


type SetupOrGame
    = Game GameModel
    | CancelSetup


type alias GameModel =
    { connection : Connection
    , stance : Tetromino.Stance
    , quarterTurns : Int
    , -- Where the mouse is over the canvas. The cell under it changes as the camera follows the
      -- player, so that is worked out when it's needed.
      pointer : Maybe { x : Float, y : Float }
    , -- How far ahead of this browser's clock the server's clock is, as far as anything the
      -- server has stamped shows. Network delay only makes a sample look smaller, so the largest
      -- one is the closest to the truth.
      clockOffset : Duration
    , -- This client's own inputs, already played on its copy of the match on the frame it guessed,
      -- that the backend hasn't answered for yet.
      unconfirmed : List { id : Int, event : TetrominoSim.InputEvent }
    , nextInputId : Int
    }


type Connection
    = -- Inputs can arrive before the state they apply to does.
      WaitingForState (List ActionWithTime)
    | Connected Timeline
    | MatchIsOver


type GameMsg
    = PointerMoved { x : Float, y : Float }
    | PointerPressed Int { x : Float, y : Float }
    | PressedRotateZ
    | PressedStandUpOrLieDown
    | PressedStopCycling
    | PressedJoin
    | PressedNothing


initSetup : SetupModel
initSetup =
    {}


{-| Two clients only see the same match if they generate the same pieces, so the match's
randomness comes from the time the backend says it began.
-}
matchSeed : ValidatedSetup -> Int
matchSeed setup =
    Time.posixToMillis setup.startedAt


initGame : GameModel
initGame =
    { connection = WaitingForState []
    , stance = Tetromino.Flat
    , quarterTurns = 0
    , pointer = Nothing
    , clockOffset = Quantity.zero
    , unconfirmed = []
    , nextInputId = 0
    }


{-| Forget this client's copy of the match. Closing a match means it is no longer kept up to date,
and opening one means getting it afresh from another player.
-}
dropMatchState : GameModel -> GameModel
dropMatchState model =
    { model | connection = WaitingForState [], pointer = Nothing, unconfirmed = [] }


initLiveMatch : LiveMatch
initLiveMatch =
    { watchers = SeqDict.empty, recentInputs = [] }


updateSetup : Id UserId -> Time.Posix -> SetupMsg -> ( SetupOrGame, Maybe ValidatedSetup )
updateSetup creatorId time msg =
    case msg of
        PressedStartGame ->
            ( Game initGame, Just { createdBy = creatorId, startedAt = time } )

        PressedCancel ->
            ( CancelSetup, Nothing )



-- Time


frameOf : ValidatedSetup -> Time.Posix -> Int
frameOf setup time =
    Quantity.ratio (Duration.from setup.startedAt time) frameDuration |> round


frameDuration : Duration
frameDuration =
    Duration.seconds (1 / TetrominoSim.framesPerSecond)


{-| How far back an input is allowed to be stamped. A client stamps its own inputs with the time
it thinks the server has, so a little slack is needed, but not so much that someone can act in
the past.
-}
maxInputDelay : Duration
maxInputDelay =
    Duration.milliseconds 300


{-| The time the backend gives an input: the client's guess at the server's clock, pulled back
into the window the server accepts.
-}
stampInput : Time.Posix -> Id UserId -> Time.Posix -> TetrominoSim.Input -> ActionWithTime
stampInput serverTime userId clientTime input =
    { userId = userId
    , time =
        clamp
            (Duration.subtractFrom serverTime maxInputDelay |> Time.posixToMillis)
            (Time.posixToMillis serverTime)
            (Time.posixToMillis clientTime)
            |> Time.millisToPosix
    , input = input
    }


{-| The latest frame no input can arrive for any more, which is the one someone opening the match
gets the state of.
-}
snapshotFrame : Time.Posix -> ValidatedSetup -> Int
snapshotFrame serverTime setup =
    frameOf setup (Duration.subtractFrom serverTime maxInputDelay)


{-| Forget inputs that nobody can need: ones before the frame a waiting watcher will get the state
of, and ones too old to change anything for those already playing.
-}
pruneInputs : Time.Posix -> ValidatedSetup -> LiveMatch -> LiveMatch
pruneInputs serverTime setup liveMatch =
    let
        neededFrom : Int
        neededFrom =
            SeqDict.foldl
                (\_ watcher frame ->
                    case watcher.waitingForFrame of
                        Just waitingFor ->
                            min frame waitingFor

                        Nothing ->
                            frame
                )
                (snapshotFrame serverTime setup)
                liveMatch.watchers
    in
    { liveMatch | recentInputs = List.filter (\action -> frameOf setup action.time >= neededFrom) liveMatch.recentInputs }


toInputEvent : ValidatedSetup -> ActionWithTime -> TetrominoSim.InputEvent
toInputEvent setup action =
    { frame = frameOf setup action.time, userId = action.userId, input = action.input }


{-| Note how far ahead the server's clock looks, going by something it stamped that has just
arrived.
-}
sampleServerTime : Time.Posix -> Time.Posix -> GameModel -> GameModel
sampleServerTime localTime serverTime model =
    let
        sample : Duration
        sample =
            Duration.from localTime serverTime
    in
    if sample |> Quantity.greaterThan model.clockOffset then
        { model | clockOffset = sample }

    else
        model


{-| What this client thinks the server's clock says. Inputs are stamped with it so that they
land on the frame the player saw when they acted.
-}
serverTimeEstimate : Time.Posix -> GameModel -> Time.Posix
serverTimeEstimate localTime model =
    Duration.addTo localTime model.clockOffset


{-| The frame this client is showing: its own clock, corrected towards the server's.
-}
currentFrame : Time.Posix -> ValidatedSetup -> GameModel -> Int
currentFrame localTime setup model =
    frameOf setup (serverTimeEstimate localTime model)



-- Playing


updateFromBackend : Time.Posix -> ValidatedSetup -> ToFrontend -> GameModel -> ( GameModel, Maybe ToBackend )
updateFromBackend time setup msg model =
    case msg of
        StateRequest frame ->
            case model.connection of
                Connected timeline ->
                    let
                        timeline2 : Timeline
                        timeline2 =
                            if (TetrominoTimeline.latest timeline).frame < frame then
                                TetrominoTimeline.advance frame timeline

                            else
                                timeline

                        -- Inputs the backend hasn't answered for yet will reach whoever is joining
                        -- through the backend, on whatever frame it gives them, so the state sent
                        -- over has to be without them.
                        withoutUnconfirmed : Timeline
                        withoutUnconfirmed =
                            List.foldl
                                (\unconfirmed timeline3 -> TetrominoTimeline.removeInput unconfirmed.event timeline3)
                                timeline2
                                model.unconfirmed
                                |> TetrominoTimeline.advance frame
                    in
                    ( { model | connection = Connected timeline2 }
                    , case TetrominoTimeline.stateAt frame withoutUnconfirmed of
                        Just state ->
                            CurrentState frame (TetrominoWire.encodeMatchState state) |> Just

                        Nothing ->
                            Nothing
                    )

                WaitingForState _ ->
                    ( model, Nothing )

                MatchIsOver ->
                    ( model, Nothing )

        JoinedMatch joined ->
            let
                model2 : GameModel
                model2 =
                    sampleServerTime time joined.serverTime model

                maybeState : Maybe TetrominoSim.MatchState
                maybeState =
                    case joined.startingState of
                        FreshMatch ->
                            TetrominoSim.init (matchSeed setup) joined.frame |> Just

                        FromAnotherPlayer bytes ->
                            TetrominoWire.decodeMatchState bytes
            in
            case ( maybeState, model2.connection ) of
                ( Just state, WaitingForState arrivedEarly ) ->
                    ( { model2
                        | connection =
                            List.foldl
                                (\action timeline -> TetrominoTimeline.addInput (toInputEvent setup action) timeline)
                                (TetrominoTimeline.init state)
                                (joined.inputs ++ arrivedEarly)
                                |> Connected
                      }
                    , Nothing
                    )

                _ ->
                    ( model2, Nothing )

        InputBroadcast action ->
            let
                model2 : GameModel
                model2 =
                    sampleServerTime time action.time model
            in
            ( case model2.connection of
                Connected timeline ->
                    { model2 | connection = Connected (TetrominoTimeline.addInput (toInputEvent setup action) timeline) }

                WaitingForState arrivedEarly ->
                    { model2 | connection = WaitingForState (arrivedEarly ++ [ action ]) }

                MatchIsOver ->
                    model2
            , Nothing
            )

        InputAccepted inputId action ->
            let
                model2 : GameModel
                model2 =
                    sampleServerTime time action.time model

                accepted : TetrominoSim.InputEvent
                accepted =
                    toInputEvent setup action

                guessed : Maybe TetrominoSim.InputEvent
                guessed =
                    List.filter (\unconfirmed -> unconfirmed.id == inputId) model2.unconfirmed
                        |> List.head
                        |> Maybe.map .event

                model3 : GameModel
                model3 =
                    { model2 | unconfirmed = List.filter (\unconfirmed -> unconfirmed.id /= inputId) model2.unconfirmed }
            in
            ( case model3.connection of
                Connected timeline ->
                    { model3
                        | connection =
                            case guessed of
                                Just event ->
                                    if event == accepted then
                                        Connected timeline

                                    else
                                        TetrominoTimeline.removeInput event timeline
                                            |> TetrominoTimeline.addInput accepted
                                            |> Connected

                                Nothing ->
                                    Connected (TetrominoTimeline.addInput accepted timeline)
                    }

                WaitingForState arrivedEarly ->
                    { model3 | connection = WaitingForState (arrivedEarly ++ [ action ]) }

                MatchIsOver ->
                    model3
            , Nothing
            )

        MatchOver ->
            ( { model | connection = MatchIsOver }, Nothing )


updateGame :
    Time.Posix
    -> ValidatedSetup
    -> Coord CssPixels
    -> Id UserId
    -> GameMsg
    -> GameModel
    -> ( GameModel, Maybe ToBackend )
updateGame time setup windowSize currentUserId msg model =
    case model.connection of
        Connected timeline ->
            case updateConnected windowSize currentUserId msg (TetrominoTimeline.latest timeline) model of
                ( model2, Just input ) ->
                    playOwnInput time setup currentUserId input timeline model2 |> Tuple.mapSecond Just

                ( model2, Nothing ) ->
                    ( model2, Nothing )

        WaitingForState _ ->
            ( model, Nothing )

        MatchIsOver ->
            ( model, Nothing )


{-| Play an input on this client's copy of the match straight away, on the frame it's showing,
rather than waiting for it to come back from the backend.
-}
playOwnInput : Time.Posix -> ValidatedSetup -> Id UserId -> TetrominoSim.Input -> Timeline -> GameModel -> ( GameModel, ToBackend )
playOwnInput time setup userId input timeline model =
    let
        serverTime : Time.Posix
        serverTime =
            serverTimeEstimate time model

        event : TetrominoSim.InputEvent
        event =
            { frame = frameOf setup serverTime, userId = userId, input = input }
    in
    ( { model
        | connection = Connected (TetrominoTimeline.addInput event timeline)
        , unconfirmed = model.unconfirmed ++ [ { id = model.nextInputId, event = event } ]
        , nextInputId = model.nextInputId + 1
      }
    , SendInput model.nextInputId serverTime input
    )


updateConnected :
    Coord CssPixels
    -> Id UserId
    -> GameMsg
    -> TetrominoSim.MatchState
    -> GameModel
    -> ( GameModel, Maybe TetrominoSim.Input )
updateConnected windowSize currentUserId msg state model =
    case msg of
        PointerMoved position ->
            ( { model | pointer = Just position }, Nothing )

        PointerPressed button position ->
            let
                ( canvasWidth, canvasHeight ) =
                    canvasSize windowSize

                model2 : GameModel
                model2 =
                    { model | pointer = Just position }

                maybeCursor : Maybe Cursor
                maybeCursor =
                    TetrominoView.screenToCell
                        canvasWidth
                        canvasHeight
                        (TetrominoView.cameraFocus currentUserId state)
                        position
                        state
            in
            case ( maybeCursor, SeqDict.get currentUserId state.players ) of
                ( Just cursor, Just player ) ->
                    case ( player.knockedOutAt, player.cycle ) of
                        ( Nothing, Ready _ ) ->
                            if button == rightMouseButton then
                                ( model2, TetrominoSim.MoveTo cursor.x cursor.y |> Just )

                            else
                                ( model2
                                , TetrominoSim.Drop
                                    { x = cursor.x
                                    , y = cursor.y
                                    , orientation = Tetromino.orientation model2.stance model2.quarterTurns
                                    }
                                    |> Just
                                )

                        ( Nothing, Cycling _ ) ->
                            if button == rightMouseButton then
                                ( model2, TetrominoSim.MoveTo cursor.x cursor.y |> Just )

                            else
                                ( model2, Nothing )

                        ( Just _, _ ) ->
                            ( model2, Nothing )

                _ ->
                    ( model2, Nothing )

        PressedRotateZ ->
            ( { model | quarterTurns = modBy 4 (model.quarterTurns + 1) }, Nothing )

        PressedStandUpOrLieDown ->
            ( { model
                | stance =
                    case model.stance of
                        Tetromino.Flat ->
                            Tetromino.Upright

                        Tetromino.Upright ->
                            Tetromino.Flat
              }
            , Nothing
            )

        PressedStopCycling ->
            ( model
            , case SeqDict.get currentUserId state.players of
                Just player ->
                    case player.cycle of
                        Cycling _ ->
                            Just TetrominoSim.StopCycling

                        Ready _ ->
                            Nothing

                Nothing ->
                    Nothing
            )

        PressedJoin ->
            ( model
            , if SeqDict.member currentUserId state.players || SeqSet.member currentUserId state.waitingPlayers then
                Nothing

              else
                Just TetrominoSim.Join
            )

        PressedNothing ->
            ( model, Nothing )


rightMouseButton : Int
rightMouseButton =
    2


pressedKey : String -> GameMsg
pressedKey key =
    case String.toLower key of
        "q" ->
            PressedRotateZ

        "e" ->
            PressedStandUpOrLieDown

        _ ->
            PressedStopCycling


matchState : GameModel -> Maybe TetrominoSim.MatchState
matchState model =
    case model.connection of
        Connected timeline ->
            TetrominoTimeline.latest timeline |> Just

        WaitingForState _ ->
            Nothing

        MatchIsOver ->
            Nothing


{-| The match as this client had it on the given frame. Clients run a little ahead or behind
each other depending on what they make of the server's clock, so this is what the end-to-end
test compares.
-}
matchStateAt : Int -> GameModel -> Maybe TetrominoSim.MatchState
matchStateAt frame model =
    case model.connection of
        Connected timeline ->
            TetrominoTimeline.stateAt frame timeline

        WaitingForState _ ->
            Nothing

        MatchIsOver ->
            Nothing


{-| Simulating a lot of frames at once (after the tab has been in the background) is spread over
several animation frames so that the page keeps drawing while it catches up.
-}
maxStepsPerFrame : Int
maxStepsPerFrame =
    3000


{-| Catch the simulation up with the frame this client is showing.
-}
animationFrame : Time.Posix -> ValidatedSetup -> GameModel -> GameModel
animationFrame time setup model =
    case model.connection of
        Connected timeline ->
            { model
                | connection =
                    TetrominoTimeline.advance
                        (min (currentFrame time setup model) ((TetrominoTimeline.latest timeline).frame + maxStepsPerFrame))
                        timeline
                        |> Connected
            }

        WaitingForState _ ->
            model

        MatchIsOver ->
            model



-- View


canvasId : HtmlId
canvasId =
    Dom.id "tetrominoGame_canvas"


{-| The canvas is a fixed shape, as wide as the tab allows.
-}
canvasSize : Coord CssPixels -> ( Int, Int )
canvasSize windowSize =
    let
        width : Int
        width =
            clamp 320 1100 (Coord.xRaw windowSize - 32)
    in
    ( width, round (toFloat width * 0.62) )


previewSize : number
previewSize =
    128


gameView : Coord CssPixels -> LocalUser -> GameModel -> Element GameMsg
gameView windowSize localUser model =
    case model.connection of
        Connected timeline ->
            connectedView windowSize localUser model (TetrominoTimeline.latest timeline)

        WaitingForState _ ->
            Ui.el
                [ Ui.padding 16, Ui.Font.size 14, Ui.contentCenterX ]
                (Ui.text "Getting the match from the players who have it open…")

        MatchIsOver ->
            Ui.el
                [ Ui.padding 16, Ui.Font.size 14, Ui.contentCenterX, Ui.id "tetrominoGame_over" ]
                (Ui.text "This match is over, everyone left it.")


connectedView : Coord CssPixels -> LocalUser -> GameModel -> TetrominoSim.MatchState -> Element GameMsg
connectedView windowSize localUser model state =
    let
        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId

        ( canvasWidth, canvasHeight ) =
            canvasSize windowSize

        maybePlayer : Maybe TetrominoSim.Player
        maybePlayer =
            SeqDict.get currentUserId state.players

        orientation : Orientation
        orientation =
            Tetromino.orientation model.stance model.quarterTurns

        shapeShown : Maybe { shape : Shape, isReady : Bool }
        shapeShown =
            case maybePlayer of
                Just player ->
                    case ( player.knockedOutAt, player.cycle ) of
                        ( Nothing, Cycling cycle ) ->
                            Just { shape = (TetrominoSim.cycleShape state.frame cycle).shape, isReady = False }

                        ( Nothing, Ready shape ) ->
                            Just { shape = shape, isReady = True }

                        ( Just _, _ ) ->
                            Nothing

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.spacing 8, Ui.padding 8, Ui.background MyUi.background1 ]
        [ Ui.el
            [ Ui.width Ui.shrink
            , Ui.centerX
            , Ui.inFront
                (case shapeShown of
                    Just { shape, isReady } ->
                        previewView (User.userColor localUser currentUserId) orientation shape isReady

                    Nothing ->
                        Ui.none
                )
            ]
            (Html.div
                [ Dom.idToAttribute canvasId
                , Html.Attributes.style "line-height" "0"
                , Html.Events.on "mousemove" (Json.Decode.map PointerMoved decodeOffset)
                , Html.Events.on "mousedown"
                    (Json.Decode.map2
                        PointerPressed
                        (Json.Decode.field "button" Json.Decode.int)
                        decodeOffset
                    )
                , Html.Events.preventDefaultOn "contextmenu" (Json.Decode.succeed ( PressedNothing, True ))
                ]
                [ WebGL.toHtmlWith
                    [ WebGL.alpha False, WebGL.depth 1, WebGL.antialias, WebGL.clearColor 0.16 0.18 0.22 1 ]
                    [ Html.Attributes.width canvasWidth
                    , Html.Attributes.height canvasHeight
                    , Html.Attributes.style "display" "block"
                    , Html.Attributes.style "border-radius" "8px"
                    ]
                    (TetrominoView.worldEntities
                        { width = canvasWidth
                        , height = canvasHeight
                        , currentUserId = currentUserId
                        , userColor = \userId -> User.userColor localUser userId |> UserColor.toColor
                        , cursor =
                            Maybe.andThen
                                (\pointer ->
                                    TetrominoView.screenToCell
                                        canvasWidth
                                        canvasHeight
                                        (TetrominoView.cameraFocus currentUserId state)
                                        pointer
                                        state
                                )
                                model.pointer
                        , ghost =
                            case shapeShown of
                                Just { shape, isReady } ->
                                    if isReady then
                                        Just { shape = shape, orientation = orientation }

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing
                        }
                        state
                    )
                ]
                |> Ui.html
            )
        , statusView currentUserId state
        ]


decodeOffset : Json.Decode.Decoder { x : Float, y : Float }
decodeOffset =
    Json.Decode.map2
        (\x y -> { x = x, y = y })
        (Json.Decode.field "offsetX" Json.Decode.float)
        (Json.Decode.field "offsetY" Json.Decode.float)


previewView : UserColor -> Orientation -> Shape -> Bool -> Element msg
previewView userColor orientation shape isReady =
    Ui.el
        [ Ui.alignRight
        , Ui.alignTop
        , Ui.move { x = -8, y = 8, z = 0 }
        , Ui.width (Ui.px previewSize)
        , Ui.height (Ui.px previewSize)
        , Ui.rounded 8
        , Ui.background (Ui.rgba 0 0 0 0.35)
        , Ui.border 2
        , Ui.borderColor
            (if isReady then
                UserColor.toColor userColor

             else
                Ui.rgba 0 0 0 0
            )
        ]
        (WebGL.toHtmlWith
            [ WebGL.alpha True, WebGL.depth 1, WebGL.antialias ]
            [ Html.Attributes.width previewSize
            , Html.Attributes.height previewSize
            , Html.Attributes.style "display" "block"
            ]
            (TetrominoView.previewEntities
                previewSize
                previewSize
                (UserColor.toColor userColor)
                orientation
                shape
            )
            |> Ui.html
        )


statusView : Id UserId -> TetrominoSim.MatchState -> Element GameMsg
statusView currentUserId state =
    let
        nextRound : String
        nextRound =
            case state.round.nextRoundAt of
                Just nextRoundAt ->
                    "Next round in " ++ secondsUntil state.frame nextRoundAt

                Nothing ->
                    "The next round starts once someone joins"

        roundInfo : String
        roundInfo =
            if state.round.number == 0 then
                nextRound

            else
                "Round " ++ String.fromInt state.round.number ++ ". " ++ nextRound
    in
    Ui.row
        [ Ui.spacing 12, Ui.Font.size 14, Ui.contentCenterX ]
        (case SeqDict.get currentUserId state.players of
            Just player ->
                case player.knockedOutAt of
                    Just _ ->
                        [ Ui.el [ Ui.Font.bold, Ui.width Ui.shrink ] (Ui.text "You were knocked out")
                        , Ui.text roundInfo
                        ]

                    Nothing ->
                        [ Ui.el [ Ui.Font.bold, Ui.width Ui.shrink ] (Ui.text roundInfo)
                        , Ui.text "Right click to move, left click to drop, Q turns the piece, E stands it up or lays it down, space stops the spinner"
                        ]

            Nothing ->
                if SeqSet.member currentUserId state.waitingPlayers then
                    [ Ui.el [ Ui.Font.bold, Ui.width Ui.shrink ] (Ui.text "You're in the next round")
                    , Ui.text roundInfo
                    ]

                else
                    [ MyUi.simpleButton (Dom.id "tetrominoGame_join") PressedJoin (Ui.text "Join the match")
                    , Ui.text roundInfo
                    ]
        )


secondsUntil : Int -> Int -> String
secondsUntil frame endFrame =
    String.fromInt (max 0 (ceiling (toFloat (endFrame - frame) / TetrominoSim.framesPerSecond))) ++ "s"


setupView : Coord CssPixels -> SetupModel -> Element SetupMsg
setupView windowSize _ =
    Ui.column
        [ Ui.spacing 16, Ui.padding 16 ]
        [ Ui.Prose.paragraph
            [ Ui.Font.size 14 ]
            [ Ui.text "Drop tetrominoes to build walls that keep the snowball throwing snowmen away from you. One hit knocks you out until the next round. Anyone in the channel can join, and the match lasts until everyone has left it." ]
        , Go.startOrCancel "tetrominoGame" (MyUi.isMobileAlt windowSize) PressedCancel PressedStartGame
        ]
