module WordSpellingGame exposing
    ( Action
    , ActionWithTime
    , GameState
    , LocalChange(..)
    , Model(..)
    , Msg(..)
    , OutMsg(..)
    , Player
    , SetupModel
    , ValidatedSetup
    , foldActions
    , gameView
    , initSetup
    , setupView
    , update
    , validateSetup
    )

{-| Were calling it this to avoid the Scrabble trademark
-}

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Go exposing (TimeControl)
import Html
import Html.Attributes
import Html.Events
import Id exposing (ChannelMessageId, Id, UserId)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyExtra
import OneOrGreater exposing (OneOrGreater)
import Random
import SeqDict exposing (SeqDict)
import SeqDictHelper
import Ui exposing (Element)
import Ui.Events
import Ui.Font


type Model
    = Setup SetupModel
    | Game { tray : Array Int }


type Msg
    = PressedGridCell ( Int, Int )
    | ChangedMainTimeInput String
    | ChangedIncrementInput String
    | ChangedTraySizeInput String
    | PressedStartGame


type alias SetupModel =
    { mainTimeInput : String
    , incrementInput : String
    , traySize : Int
    , error : Maybe String
    }


type alias ValidatedSetup =
    { timeControls : TimeControl
    , traySize : OneOrGreater
    , createdBy : Id UserId
    , seed : Int
    }


initSetup : SetupModel
initSetup =
    { mainTimeInput = "10"
    , incrementInput = "5"
    , traySize = 7
    , error = Nothing
    }


type OutMsg
    = OutLocalChange LocalChange


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


type Action
    = PlaceWord ( Int, Int ) Direction Letter
    | ReplaceTray


type alias ActionWithTime =
    { time : Time.Posix, change : Action }


type alias GameState =
    { board : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
    , players : Nonempty Player
    , turnCount : Int
    }


type alias Player =
    { userId : Id UserId
    , tray : List LetterOrWildcard
    , score : Int
    }


gridSize : number
gridSize =
    15


type Direction
    = Left
    | Right
    | Up
    | Down


type LetterOrWildcard
    = Letter Letter
    | Wildcard


initGameState : ValidatedSetup -> GameState
initGameState setup =
    let
        initialBoard : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
        initialBoard =
            SeqDict.empty
    in
    { board = initialBoard
    , players =
        Nonempty
            { userId = setup.createdBy
            , tray = getLetters setup.traySize setup initialBoard [] 0
            , score = 0
            }
            []
    , turnCount = 0
    }


getLetters :
    OneOrGreater
    -> ValidatedSetup
    -> SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
    -> List Player
    -> Int
    -> List LetterOrWildcard
getLetters count setup board players turnCount =
    let
        startingLetters : SeqDict LetterOrWildcard OneOrGreater
        startingLetters =
            ( Wildcard, OneOrGreater.two )
                :: List.map (\letter -> ( Letter letter, (letterData letter).total )) allLetters
                |> SeqDict.fromList

        remainingLetters : SeqDict LetterOrWildcard OneOrGreater
        remainingLetters =
            SeqDict.foldl
                (\_ { letter, isWildcard } startingLetters2 ->
                    SeqDictHelper.decrement
                        (if isWildcard then
                            Wildcard

                         else
                            Letter letter
                        )
                        startingLetters2
                )
                startingLetters
                board

        remainingLetters3 : SeqDict LetterOrWildcard OneOrGreater
        remainingLetters3 =
            List.foldl
                (\player remainingLetters2 -> List.foldl SeqDictHelper.decrement remainingLetters2 player.tray)
                remainingLetters
                players
    in
    Random.step
        (SeqDict.foldl
            (\letter count2 list -> List.repeat (OneOrGreater.toInt count2) letter ++ list)
            []
            remainingLetters3
            |> shuffle
        )
        (Random.initialSeed (setup.seed + turnCount))
        |> Tuple.first
        |> List.take (OneOrGreater.toInt count)


{-| Shuffle the list. Takes O(_n_ log _n_) time and no extra space. Original code found here <https://github.com/elm-community/random-extra/blob/d52055975644ad401709c2aff14dab9ca93e44a0/src/Random/List.elm#L88>
-}
shuffle : List a -> Random.Generator (List a)
shuffle list =
    Random.map
        (\independentSeed ->
            list
                |> List.foldl
                    (\item ( acc, seed ) ->
                        let
                            ( tag, nextSeed ) =
                                Random.step (Random.int Random.minInt Random.maxInt) seed
                        in
                        ( ( item, tag ) :: acc, nextSeed )
                    )
                    ( [], independentSeed )
                |> Tuple.first
                |> List.sortBy Tuple.second
                |> List.map Tuple.first
        )
        Random.independentSeed


foldActions : ValidatedSetup -> Array ActionWithTime -> GameState
foldActions setup actions =
    Array.foldl (updateAction setup) (initGameState setup) actions


updateAction : ValidatedSetup -> ActionWithTime -> GameState -> GameState
updateAction setup action state =
    case action.change of
        PlaceWord ( x, y ) _ letter ->
            { state
                | board = SeqDict.insert ( x, y ) { letter = letter, isWildcard = False } state.board
                , players =
                    NonemptyExtra.update
                        state.turnCount
                        (\player ->
                            { player
                                | tray = List.Extra.remove (Letter letter) player.tray
                                , score = player.score + (letterData letter).score
                            }
                        )
                        state.players
                , turnCount = state.turnCount + 1
            }

        ReplaceTray ->
            { state
                | players =
                    NonemptyExtra.update
                        state.turnCount
                        (\player ->
                            { player
                                | tray =
                                    getLetters
                                        setup.traySize
                                        setup
                                        state.board
                                        (NonemptyExtra.set state.turnCount { player | tray = [] } state.players
                                            |> List.Nonempty.toList
                                        )
                                        state.turnCount
                            }
                        )
                        state.players
                , turnCount = state.turnCount + 1
            }


update : Time.Posix -> Id UserId -> Msg -> Maybe Model -> ( Maybe Model, List OutMsg )
update time currentUserId msg model =
    case msg of
        ChangedMainTimeInput input ->
            ( Maybe.map (mapSetup (\setup -> { setup | mainTimeInput = input, error = Nothing })) model, [] )

        ChangedIncrementInput input ->
            ( Maybe.map (mapSetup (\setup -> { setup | incrementInput = input, error = Nothing })) model, [] )

        ChangedTraySizeInput input ->
            ( Maybe.map
                (mapSetup
                    (\setup ->
                        { setup
                            | traySize = String.toInt (String.trim input) |> Maybe.withDefault setup.traySize
                            , error = Nothing
                        }
                    )
                )
                model
            , []
            )

        PressedStartGame ->
            case model of
                Just (Setup setup) ->
                    case validateSetup currentUserId time setup of
                        Ok validated ->
                            ( Just (Game { tray = Array.empty }), [ OutLocalChange (StartMatch time validated) ] )

                        Err error ->
                            ( Just (Setup { setup | error = Just error }), [] )

                _ ->
                    ( model, [] )

        PressedGridCell _ ->
            ( model, [] )


mapSetup : (SetupModel -> SetupModel) -> Model -> Model
mapSetup function model =
    case model of
        Setup setup ->
            Setup (function setup)

        Game _ ->
            model


validateSetup : Id UserId -> Time.Posix -> SetupModel -> Result String ValidatedSetup
validateSetup createdBy time setup =
    case parseTimeControl setup of
        Err error ->
            Err error

        Ok timeControls ->
            case OneOrGreater.fromInt setup.traySize of
                Just traySize ->
                    Ok
                        { createdBy = createdBy
                        , timeControls = timeControls
                        , traySize = traySize
                        , seed =
                            -- Round the time to the nearest 10 seconds so that small timing changes don't break an end-to-end test
                            Time.posixToMillis time // 10000 |> (*) 10000 |> (+) (Id.toInt createdBy)
                        }

                Nothing ->
                    Err "Tray size must be at least 1"


parseTimeControl : SetupModel -> Result String TimeControl
parseTimeControl setup =
    case String.toFloat (String.trim setup.mainTimeInput) of
        Nothing ->
            Err "Main time: enter a number of minutes"

        Just minutes ->
            if minutes <= 0 then
                Err "Main time must be greater than 0"

            else
                case String.toFloat (String.trim setup.incrementInput) of
                    Nothing ->
                        Err "Increment: enter a number of seconds"

                    Just increment ->
                        if increment < 0 then
                            Err "Increment cannot be negative"

                        else
                            Ok { mainTime = Duration.minutes minutes, increment = Duration.seconds increment }


gameView : Id UserId -> ValidatedSetup -> GameState -> Element Msg
gameView currentUserId validatedSetup gameState =
    Ui.column
        [ Ui.spacing 16, Ui.padding 16 ]
        [ statusView currentUserId gameState
        , boardView gameState
        , trayView currentUserId gameState
        ]


statusView : Id UserId -> GameState -> Element Msg
statusView currentUserId gameState =
    let
        currentPlayer : Player
        currentPlayer =
            List.Nonempty.get gameState.turnCount gameState.players
    in
    Ui.column
        [ Ui.spacing 4 ]
        (List.Nonempty.toList gameState.players
            |> List.map
                (\player ->
                    let
                        name : String
                        name =
                            if player.userId == currentUserId then
                                "You"

                            else
                                "Opponent"

                        turnMarker : String
                        turnMarker =
                            if player.userId == currentPlayer.userId then
                                " (their turn)"

                            else
                                ""
                    in
                    Ui.el
                        [ if player.userId == currentPlayer.userId then
                            Ui.Font.weight 700

                          else
                            Ui.Font.weight 400
                        ]
                        (Ui.text (name ++ ": " ++ String.fromInt player.score ++ turnMarker))
                )
        )


boardView : GameState -> Element Msg
boardView gameState =
    Ui.column
        [ Ui.spacing 2, Ui.width Ui.shrink ]
        (List.map
            (\y ->
                Ui.row
                    [ Ui.spacing 2 ]
                    (List.map (\x -> cellView ( x, y ) gameState) (List.range 0 (gridSize - 1)))
            )
            (List.range 0 (gridSize - 1))
        )


cellView : ( Int, Int ) -> GameState -> Element Msg
cellView position gameState =
    let
        commonAttributes : List (Ui.Attribute msg)
        commonAttributes =
            [ Ui.width (Ui.px 28)
            , Ui.height (Ui.px 28)
            , Ui.border 1
            , Ui.borderColor MyUi.inputBorder
            , Ui.contentCenterX
            , Ui.contentCenterY
            , Ui.Font.size 16
            , Ui.Font.weight 600
            ]
    in
    case SeqDict.get position gameState.board of
        Just tile ->
            Ui.el
                (Ui.background (Ui.rgb 240 220 130) :: commonAttributes)
                (Ui.text
                    (if tile.isWildcard then
                        " "

                     else
                        (letterData tile.letter).text
                    )
                )

        Nothing ->
            Ui.el
                (Ui.Events.onClick (PressedGridCell position)
                    :: Ui.pointer
                    :: Ui.background (Ui.rgb 250 250 250)
                    :: commonAttributes
                )
                Ui.none


trayView : Id UserId -> GameState -> Element Msg
trayView currentUserId gameState =
    case List.Extra.find (\player -> player.userId == currentUserId) (List.Nonempty.toList gameState.players) of
        Just player ->
            Ui.row
                [ Ui.spacing 4 ]
                (List.map tileView player.tray)

        Nothing ->
            Ui.none


tileView : LetterOrWildcard -> Element Msg
tileView letterOrWildcard =
    Ui.el
        [ Ui.width (Ui.px 32)
        , Ui.height (Ui.px 32)
        , Ui.border 1
        , Ui.borderColor MyUi.inputBorder
        , Ui.background (Ui.rgb 240 220 130)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.Font.size 18
        , Ui.Font.weight 600
        ]
        (Ui.text
            (case letterOrWildcard of
                Letter letter ->
                    (letterData letter).text

                Wildcard ->
                    " "
            )
        )


setupView : Coord CssPixels -> SetupModel -> Element Msg
setupView windowSize setup =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    Ui.column
        [ Ui.spacing
            (if isMobile then
                12

             else
                16
            )
        , Ui.padding
            (if isMobile then
                12

             else
                24
            )
        , Ui.background MyUi.tabBackground
        ]
        [ setupSection
            "Tray size (letters each player holds)"
            (numberInput
                { htmlId = "wsg_traySizeInput"
                , minValue = 1
                , maxValue = 20
                , value = String.fromInt setup.traySize
                , onChange = ChangedTraySizeInput
                }
            )
        , setupSection
            "Time control"
            (Ui.row [ Ui.spacing 8, Ui.width Ui.shrink, Ui.contentBottom ]
                [ timeInput "wsg_mainTimeInput" "Main time (minutes)" setup.mainTimeInput ChangedMainTimeInput
                , timeInput "wsg_incrementInput" "Increment (seconds)" setup.incrementInput ChangedIncrementInput
                ]
            )
        , case setup.error of
            Just error ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text error)

            Nothing ->
                Ui.none
        , MyUi.simpleButton (Dom.id "wsg_start") PressedStartGame (Ui.text "Start game")
        ]


setupSection : String -> Element Msg -> Element Msg
setupSection title content =
    Ui.column
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text title)
        , content
        ]


numberInput :
    { htmlId : String
    , minValue : Int
    , maxValue : Int
    , value : String
    , onChange : String -> Msg
    }
    -> Element Msg
numberInput args =
    Html.input
        [ Html.Attributes.id args.htmlId
        , Html.Attributes.type_ "number"
        , Html.Attributes.min (String.fromInt args.minValue)
        , Html.Attributes.max (String.fromInt args.maxValue)
        , Html.Attributes.value args.value
        , Html.Attributes.style "font-size" "inherit"
        , Html.Attributes.style "width" "50px"
        , Html.Attributes.style "padding" "8px"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Events.onInput args.onChange
        ]
        []
        |> Ui.html


timeInput : String -> String -> String -> (String -> Msg) -> Element Msg
timeInput htmlId label value onChange =
    Ui.column [ Ui.spacing 4, Ui.width Ui.shrink ]
        [ Ui.el [ Ui.Font.size 12 ] (Ui.text label)
        , Html.input
            [ Html.Attributes.id htmlId
            , Html.Attributes.type_ "number"
            , Html.Attributes.min "0"
            , Html.Attributes.step "1"
            , Html.Attributes.value value
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "width" "70px"
            , Html.Attributes.style "padding" "8px"
            , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
            , Html.Attributes.style "border-radius" "4px"
            , Html.Events.onInput onChange
            ]
            []
            |> Ui.html
        ]


allLetters : List Letter
allLetters =
    [ A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z ]


type alias LetterData =
    { score : Int
    , text : String
    , total : OneOrGreater
    }


letterData : Letter -> LetterData
letterData letter =
    case letter of
        A ->
            { score = 1, text = "A", total = OneOrGreater.nine }

        B ->
            { score = 3, text = "B", total = OneOrGreater.two }

        C ->
            { score = 3, text = "C", total = OneOrGreater.two }

        D ->
            { score = 2, text = "D", total = OneOrGreater.four }

        E ->
            { score = 1, text = "E", total = OneOrGreater.twelve }

        F ->
            { score = 4, text = "F", total = OneOrGreater.two }

        G ->
            { score = 2, text = "G", total = OneOrGreater.three }

        H ->
            { score = 4, text = "H", total = OneOrGreater.two }

        I ->
            { score = 1, text = "I", total = OneOrGreater.nine }

        J ->
            { score = 8, text = "J", total = OneOrGreater.one }

        K ->
            { score = 5, text = "K", total = OneOrGreater.one }

        L ->
            { score = 1, text = "L", total = OneOrGreater.four }

        M ->
            { score = 3, text = "M", total = OneOrGreater.two }

        N ->
            { score = 1, text = "N", total = OneOrGreater.six }

        O ->
            { score = 1, text = "O", total = OneOrGreater.eight }

        P ->
            { score = 3, text = "P", total = OneOrGreater.two }

        Q ->
            { score = 10, text = "Q", total = OneOrGreater.one }

        R ->
            { score = 1, text = "R", total = OneOrGreater.six }

        S ->
            { score = 1, text = "S", total = OneOrGreater.four }

        T ->
            { score = 1, text = "T", total = OneOrGreater.six }

        U ->
            { score = 1, text = "U", total = OneOrGreater.four }

        V ->
            { score = 4, text = "V", total = OneOrGreater.two }

        W ->
            { score = 4, text = "W", total = OneOrGreater.two }

        X ->
            { score = 8, text = "X", total = OneOrGreater.one }

        Y ->
            { score = 4, text = "Y", total = OneOrGreater.two }

        Z ->
            { score = 10, text = "Z", total = OneOrGreater.one }


type Letter
    = A
    | B
    | C
    | D
    | E
    | F
    | G
    | H
    | I
    | J
    | K
    | L
    | M
    | N
    | O
    | P
    | Q
    | R
    | S
    | T
    | U
    | V
    | W
    | X
    | Y
    | Z
