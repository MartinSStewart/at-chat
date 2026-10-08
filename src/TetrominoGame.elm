module TetrominoGame exposing
    ( ActionWithTime
    , GameModel
    , GameMsg(..)
    , LocalChange(..)
    , SetupModel
    , SetupMsg(..)
    , SetupOrGame(..)
    , Shared
    , ValidatedSetup
    , animationFrame
    , canvasId
    , foldActions
    , gameView
    , initGame
    , initSetup
    , initShared
    , isValidAction
    , pressedKey
    , sampleServerTime
    , serverTimeEstimate
    , setupView
    , updateAction
    , updateGame
    , updateSetup
    )

{-| The tetromino fort game: the part that at-chat's game framework talks to. The rules live in
`TetrominoSim` and the drawing in `TetrominoView`.

Every client runs the same simulation over the same inputs, so an input only counts once the
backend has stamped it with the time it arrived (`isValidAction` keeps that stamp inside the
window the server allows). A client applies its own inputs straight away at the frame it is
showing and `TetrominoTimeline` re-runs the affected frames when the server's stamp turns out to
differ.

-}

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
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
import SeqDict
import Tetromino exposing (Orientation, Shape)
import TetrominoSim exposing (PieceCycle(..))
import TetrominoTimeline exposing (Timeline)
import TetrominoView exposing (Cursor)
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


type alias ActionWithTime =
    { userId : Id UserId, time : Time.Posix, input : TetrominoSim.Input }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


{-| The inputs of a match, with the times turned into frame numbers. The states they lead to are
too expensive to keep here, since every open match would recompute them on each change; they live
in `GameModel` instead.
-}
type alias Shared =
    { inputs : Array TetrominoSim.InputEvent }


type alias SetupModel =
    {}


type SetupMsg
    = PressedStartGame
    | PressedCancel


type SetupOrGame
    = Setup SetupModel
    | Game GameModel
    | CancelSetup


type alias GameModel =
    { timeline : Timeline
    , orientation : Orientation
    , cursor : Maybe Cursor
    , -- How far ahead of this browser's clock the server's clock is, as far as anything the
      -- server has stamped shows. Network delay only makes a sample look smaller, so the largest
      -- one is the closest to the truth.
      clockOffset : Duration
    }


type GameMsg
    = PointerMoved { x : Float, y : Float }
    | PointerPressed Int { x : Float, y : Float }
    | PressedRotateZ
    | PressedRotateY
    | PressedStopCycling
    | PressedJoin


initSetup : SetupModel
initSetup =
    {}


initGame : ValidatedSetup -> GameModel
initGame setup =
    { timeline = TetrominoTimeline.init (Time.posixToMillis setup.startedAt)
    , orientation = Tetromino.identity
    , cursor = Nothing
    , clockOffset = Quantity.zero
    }


initShared : Shared
initShared =
    { inputs = Array.empty }


updateSetup : Id UserId -> Time.Posix -> SetupMsg -> SetupModel -> ( SetupOrGame, Maybe ValidatedSetup )
updateSetup creatorId time msg model =
    case msg of
        PressedStartGame ->
            let
                setup : ValidatedSetup
                setup =
                    { createdBy = creatorId, startedAt = time }
            in
            ( Game (initGame setup), Just setup )

        PressedCancel ->
            ( CancelSetup, Nothing )



-- Actions


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


{-| Whether the backend should take an action as it stands. The time a client sends is its guess
at the server's clock, so it gets pulled back into the window the server will accept.
-}
isValidAction : Time.Posix -> Id UserId -> ActionWithTime -> Maybe ActionWithTime
isValidAction serverTime userId action =
    if action.userId == userId then
        Just
            { action
                | time =
                    clamp
                        (Duration.subtractFrom serverTime maxInputDelay |> Time.posixToMillis)
                        (Time.posixToMillis serverTime)
                        (Time.posixToMillis action.time)
                        |> Time.millisToPosix
            }

    else
        Nothing


foldActions : ValidatedSetup -> Array ActionWithTime -> Shared
foldActions setup actions =
    Array.foldl (updateAction setup) initShared actions


updateAction : ValidatedSetup -> ActionWithTime -> Shared -> Shared
updateAction setup action shared =
    { inputs =
        Array.push
            { frame = frameOf setup action.time, userId = action.userId, input = action.input }
            shared.inputs
    }


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



-- Playing


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


updateGame :
    Coord CssPixels
    -> Id UserId
    -> GameMsg
    -> GameModel
    -> ( GameModel, Maybe TetrominoSim.Input )
updateGame windowSize currentUserId msg model =
    let
        state : TetrominoSim.MatchState
        state =
            TetrominoTimeline.latest model.timeline

        ( canvasWidth, canvasHeight ) =
            canvasSize windowSize
    in
    case msg of
        PointerMoved position ->
            ( { model | cursor = TetrominoView.screenToCell canvasWidth canvasHeight position state }, Nothing )

        PointerPressed button position ->
            let
                model2 : GameModel
                model2 =
                    { model | cursor = TetrominoView.screenToCell canvasWidth canvasHeight position state }
            in
            case ( model2.cursor, SeqDict.get currentUserId state.players ) of
                ( Just cursor, Just player ) ->
                    case ( player.diedAt, player.cycle ) of
                        ( Nothing, Ready _ ) ->
                            if button == rightMouseButton then
                                ( model2
                                , TetrominoSim.Drop { x = cursor.x, y = cursor.y, orientation = model2.orientation }
                                    |> Just
                                )

                            else
                                ( model2, TetrominoSim.MoveTo cursor.x cursor.y |> Just )

                        ( Nothing, Cycling _ ) ->
                            if button == rightMouseButton then
                                ( model2, Nothing )

                            else
                                ( model2, TetrominoSim.MoveTo cursor.x cursor.y |> Just )

                        ( Just _, _ ) ->
                            ( model2, Nothing )

                ( _, _ ) ->
                    ( model2, Nothing )

        PressedRotateZ ->
            ( { model | orientation = Tetromino.rotateAroundZ model.orientation }, Nothing )

        PressedRotateY ->
            ( { model | orientation = Tetromino.rotateAroundY model.orientation }, Nothing )

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
            , if SeqDict.member currentUserId state.players then
                Nothing

              else
                Just TetrominoSim.Join
            )


rightMouseButton : Int
rightMouseButton =
    2


pressedKey : String -> GameMsg
pressedKey key =
    case String.toLower key of
        "q" ->
            PressedRotateZ

        "e" ->
            PressedRotateY

        _ ->
            PressedStopCycling


{-| Catch the simulation up with the frame this client is showing.
-}
animationFrame : Time.Posix -> ValidatedSetup -> Shared -> GameModel -> GameModel
animationFrame time setup shared model =
    { model | timeline = TetrominoTimeline.update (currentFrame time setup model) shared.inputs model.timeline }



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
    let
        state : TetrominoSim.MatchState
        state =
            TetrominoTimeline.latest model.timeline

        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId

        ( canvasWidth, canvasHeight ) =
            canvasSize windowSize

        maybePlayer : Maybe TetrominoSim.Player
        maybePlayer =
            SeqDict.get currentUserId state.players

        shapeShown : Maybe { shape : Shape, isReady : Bool }
        shapeShown =
            case maybePlayer of
                Just player ->
                    case player.cycle of
                        Cycling cycle ->
                            Just { shape = (TetrominoSim.cycleShape state.frame cycle).shape, isReady = False }

                        Ready shape ->
                            Just { shape = shape, isReady = True }

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
                        previewView (User.userColor localUser currentUserId) model.orientation shape isReady

                    Nothing ->
                        Ui.none
                )
            ]
            (WebGL.toHtmlWith
                [ WebGL.alpha False, WebGL.depth 1, WebGL.antialias, WebGL.clearColor 0.16 0.18 0.22 1 ]
                [ Html.Attributes.width canvasWidth
                , Html.Attributes.height canvasHeight
                , Html.Attributes.style "display" "block"
                , Html.Attributes.style "border-radius" "8px"
                , Dom.idToAttribute canvasId
                , Html.Events.on "mousemove" (Json.Decode.map PointerMoved offsetDecoder)
                , Html.Events.on "mousedown"
                    (Json.Decode.map2
                        PointerPressed
                        (Json.Decode.field "button" Json.Decode.int)
                        offsetDecoder
                    )
                , Html.Events.preventDefaultOn "contextmenu" (Json.Decode.succeed ( PointerMoved { x = -1, y = -1 }, True ))
                ]
                (TetrominoView.worldEntities
                    { width = canvasWidth
                    , height = canvasHeight
                    , frame = state.frame
                    , currentUserId = currentUserId
                    , userColor = \userId -> User.userColor localUser userId |> UserColor.toColor
                    , cursor = model.cursor
                    , ghost =
                        case ( shapeShown, maybePlayer ) of
                            ( Just { shape, isReady }, Just player ) ->
                                if isReady && player.diedAt == Nothing then
                                    Just { shape = shape, orientation = model.orientation }

                                else
                                    Nothing

                            _ ->
                                Nothing
                    }
                    state
                )
                |> Ui.html
            )
        , statusView state maybePlayer
        ]


offsetDecoder : Json.Decode.Decoder { x : Float, y : Float }
offsetDecoder =
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


statusView : TetrominoSim.MatchState -> Maybe TetrominoSim.Player -> Element GameMsg
statusView state maybePlayer =
    Ui.row
        [ Ui.spacing 12, Ui.Font.size 14, Ui.contentCenterX ]
        (case maybePlayer of
            Just player ->
                case player.diedAt of
                    Just _ ->
                        [ Ui.el [ Ui.Font.bold, Ui.width Ui.shrink ] (Ui.text "You were knocked out") ]

                    Nothing ->
                        [ Ui.el
                            [ Ui.Font.bold, Ui.width Ui.shrink ]
                            (Ui.text
                                (String.repeat player.health "♥"
                                    ++ String.repeat (TetrominoSim.maxHealth - player.health) "♡"
                                )
                            )
                        , Ui.text "Left click to move, right click to drop, Q and E turn the piece, space stops the spinner"
                        ]

            Nothing ->
                [ MyUi.simpleButton (Dom.id "tetrominoGame_join") PressedJoin (Ui.text "Join the match")
                , Ui.text
                    (if SeqDict.isEmpty state.players then
                        "Nobody is playing yet"

                     else
                        String.fromInt (SeqDict.size state.players) ++ " playing"
                    )
                ]
        )


setupView : Coord CssPixels -> SetupModel -> Element SetupMsg
setupView windowSize _ =
    Ui.column
        [ Ui.spacing 16, Ui.padding 16 ]
        [ Ui.Prose.paragraph
            [ Ui.Font.size 14 ]
            [ Ui.text "Drop tetrominoes to build walls that keep the snowball throwing snowmen away from you. Anyone in the channel can join the match while it's running." ]
        , Go.startOrCancel "tetrominoGame" (MyUi.isMobileAlt windowSize) PressedCancel PressedStartGame
        ]
