module Game exposing
    ( BackendGameData(..)
    , FrontendGameData(..)
    , Game(..)
    , LocalChange(..)
    , MatchData(..)
    , Model
    , Msg(..)
    , OutMsg(..)
    , Setup(..)
    , addGoAction
    , addPublicLink
    , addWordSpellingGameAction
    , audio
    , dragEnd
    , dragStart
    , gameChangeFromServer
    , gameToString
    , hasPendingTurn
    , initMatchData
    , initModel
    , pressedKey
    , routeRequest
    , update
    , view
    , wordSpellingMatchData
    )

import Array exposing (Array)
import Audio exposing (Audio)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Go
import Html
import Html.Attributes
import Html.Events
import Id exposing (ChannelMessageId, GamePublicId, Id, UserId)
import List.Nonempty
import Message exposing (GameType(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Font
import Ui.Lazy
import User exposing (LocalUser)
import UserSession exposing (ToBeFilledInByBackend(..))
import WordSpellingGame


type alias Model =
    { startedGames : SeqDict (Id ChannelMessageId) Game, setup : Setup }


type Game
    = GoModel_Game Go.GameModel
    | WordSpellingGame_Game WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Go.SetupModel
    | WordSpellingGame_Setup WordSpellingGame.SetupModel


type BackendGameData
    = GameData_Go Go.ValidatedSetup (Array Go.ActionWithTime)
    | GameData_WordSpellingGame WordSpellingGame.ValidatedSetup (Array WordSpellingGame.ActionWithTime) WordSpellingGame.Shared


{-| OpaqueVariants
-}
type FrontendGameData
    = FrontendGameData_Go Go.ValidatedSetup (Array Go.ActionWithTime) Go.Shared
    | FrontendGameData_WordSpellingGame WordSpellingGame.ValidatedSetup (Array WordSpellingGame.ActionWithTime) WordSpellingGame.Shared


type Msg
    = GoGameMsg Go.GameMsg
    | GoSetupMsg Go.SetupMsg
    | WordSpellingGameMsg WordSpellingGame.GameMsg
    | WordSpellingSetupMsg WordSpellingGame.SetupMsg
    | PressedShareMatch (Id ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Id ChannelMessageId)
    | PressedReset
    | PressedSelectGame GameType
    | NoOpMsg


{-| OpaqueVariants
-}
type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (SecretId GamePublicId)
        }


addPublicLink : SecretId GamePublicId -> MatchData -> MatchData
addPublicLink publicLink (MatchData match) =
    { match | publicLink = Just publicLink } |> MatchData


audio : Audio.Source -> Id UserId -> Id ChannelMessageId -> MatchData -> Model -> Audio
audio popSound currentUserId matchId (MatchData matchData) model =
    case matchData.data of
        FrontendGameData_Go _ _ _ ->
            case SeqDict.get matchId model.startedGames of
                Just (GoModel_Game model2) ->
                    Go.audio popSound model2

                _ ->
                    Audio.silence

        FrontendGameData_WordSpellingGame _ _ shared ->
            case SeqDict.get matchId model.startedGames of
                Just (WordSpellingGame_Game model2) ->
                    WordSpellingGame.audio popSound currentUserId shared model2

                _ ->
                    Audio.silence


initModel : Model
initModel =
    { setup = GameSelect
    , startedGames = SeqDict.empty
    }


initMatchData : BackendGameData -> Maybe (SecretId GamePublicId) -> MatchData
initMatchData gameData publicLink =
    { data =
        case gameData of
            GameData_Go setup actions ->
                FrontendGameData_Go setup actions (Go.foldActions setup actions)

            GameData_WordSpellingGame setup actions shared ->
                FrontendGameData_WordSpellingGame setup actions shared
    , publicLink = publicLink
    }
        |> MatchData


{-| Extract the word spelling setup and current game state from a match, if it is one.
-}
wordSpellingMatchData : MatchData -> Maybe ( WordSpellingGame.ValidatedSetup, WordSpellingGame.Shared )
wordSpellingMatchData (MatchData match) =
    case match.data of
        FrontendGameData_WordSpellingGame setup _ state ->
            Just ( setup, state )

        FrontendGameData_Go _ _ _ ->
            Nothing


addGoAction : Go.ActionWithTime -> MatchData -> MatchData
addGoAction action (MatchData match) =
    { match
        | data =
            case match.data of
                FrontendGameData_Go setup actions cache ->
                    FrontendGameData_Go setup (Array.push action actions) (Go.updateAction setup action cache)

                FrontendGameData_WordSpellingGame _ _ _ ->
                    match.data
    }
        |> MatchData


routeRequest :
    Time.Posix
    -> Id UserId
    -> Id ChannelMessageId
    -> SeqDict (Id ChannelMessageId) MatchData
    -> SeqDict (Id UserId) Model
    -> SeqDict (Id UserId) Model
routeRequest time otherUserId matchId matchData models =
    case SeqDict.get matchId matchData of
        Just (MatchData matchData2) ->
            SeqDict.update
                otherUserId
                (\maybeModel ->
                    let
                        model =
                            Maybe.withDefault initModel maybeModel
                    in
                    (case matchData2.data of
                        FrontendGameData_Go setup _ state ->
                            { model
                                | startedGames =
                                    SeqDict.update
                                        matchId
                                        (\maybeGame ->
                                            case maybeGame of
                                                Just game ->
                                                    maybeGame

                                                Nothing ->
                                                    GoModel_Game Go.initGame |> Just
                                        )
                                        model.startedGames
                            }

                        FrontendGameData_WordSpellingGame setup _ _ ->
                            { model
                                | startedGames =
                                    SeqDict.update
                                        matchId
                                        (\maybeGame ->
                                            case maybeGame of
                                                Just game ->
                                                    maybeGame

                                                Nothing ->
                                                    WordSpellingGame.initGame time setup |> WordSpellingGame_Game |> Just
                                        )
                                        model.startedGames
                            }
                    )
                        |> Just
                )
                models

        Nothing ->
            models


addWordSpellingGameAction : WordSpellingGame.ActionWithTime -> MatchData -> MatchData
addWordSpellingGameAction action (MatchData match) =
    { match
        | data =
            case match.data of
                FrontendGameData_Go _ _ _ ->
                    match.data

                FrontendGameData_WordSpellingGame setup actions cache ->
                    FrontendGameData_WordSpellingGame
                        setup
                        (Array.push action actions)
                        (WordSpellingGame.updateAction setup action cache)
    }
        |> MatchData


hasPendingTurn : Id UserId -> SeqDict (Id ChannelMessageId) MatchData -> SeqSet (Id ChannelMessageId)
hasPendingTurn userId matches =
    SeqDict.foldl
        (\matchId (MatchData match) set ->
            case match.data of
                FrontendGameData_Go setup _ cache ->
                    if Go.isLocalUsersTurn userId setup cache then
                        SeqSet.insert matchId set

                    else
                        set

                FrontendGameData_WordSpellingGame _ _ cache ->
                    case WordSpellingGame.isPlayerTurn userId cache of
                        WordSpellingGame.NotJoined ->
                            set

                        WordSpellingGame.Joined ->
                            set

                        WordSpellingGame.JoinedAndItsTheirTurn ->
                            SeqSet.insert matchId set
        )
        SeqSet.empty
        matches


type LocalChange
    = CreatePublicLink (Id ChannelMessageId) (ToBeFilledInByBackend (SecretId GamePublicId))
    | LocalChange_Go (Id ChannelMessageId) Go.LocalChange
    | LocalChange_WordSpellingGame (Id ChannelMessageId) WordSpellingGame.LocalChange


type OutMsg
    = OutLocalChange LocalChange
    | CopyText String
    | OutSelectMatch (Maybe (Id ChannelMessageId))


update :
    Time.Posix
    -> Id UserId
    -> Id UserId
    -> Msg
    -> Id ChannelMessageId
    -> Maybe ( Id ChannelMessageId, MatchData )
    -> Model
    -> ( Model, List OutMsg )
update time currentUserId otherUserId msg newMatchId maybeMatch model =
    case msg of
        PressedShareMatch matchId ->
            ( model, [ OutLocalChange (CreatePublicLink matchId EmptyPlaceholder) ] )

        PressedCopyLink text ->
            ( model, [ CopyText text ] )

        GoGameMsg goMsg ->
            case maybeMatch of
                Just ( matchId, MatchData matchData ) ->
                    case matchData.data of
                        FrontendGameData_Go setup _ cache ->
                            let
                                ( goModel, maybeLocalChange ) =
                                    Go.updateGame
                                        time
                                        currentUserId
                                        goMsg
                                        setup
                                        cache
                                        (case SeqDict.get matchId model.startedGames of
                                            Just (GoModel_Game goModel2) ->
                                                goModel2

                                            _ ->
                                                Go.initGame
                                        )
                            in
                            ( { model | startedGames = SeqDict.insert matchId (GoModel_Game goModel) model.startedGames }
                            , case maybeLocalChange of
                                Just localChange ->
                                    [ OutLocalChange (LocalChange_Go matchId (Go.Action localChange)) ]

                                Nothing ->
                                    []
                            )

                        _ ->
                            ( model, [] )

                Nothing ->
                    ( model, [] )

        GoSetupMsg goMsg ->
            let
                ( goModel, maybeStartMatch ) =
                    Go.updateSetup
                        currentUserId
                        otherUserId
                        goMsg
                        (case model.setup of
                            GoModel_Setup setup ->
                                setup

                            _ ->
                                Go.initSetup
                        )
            in
            ( case goModel of
                Go.Setup setup ->
                    { model | setup = GoModel_Setup setup }

                Go.Game gameModel ->
                    { model | startedGames = SeqDict.insert newMatchId (GoModel_Game gameModel) model.startedGames }
            , case maybeStartMatch of
                Just setup ->
                    -- A brand new match takes the next message id, then we navigate to it.
                    [ OutLocalChange (LocalChange_Go newMatchId (Go.StartMatch time setup))
                    , OutSelectMatch (Just newMatchId)
                    ]

                Nothing ->
                    []
            )

        WordSpellingGameMsg wordSpellingGameMsg ->
            case maybeMatch of
                Just ( matchId, MatchData matchData ) ->
                    case ( matchData.data, SeqDict.get matchId model.startedGames ) of
                        ( FrontendGameData_WordSpellingGame setup _ cache, Just (WordSpellingGame_Game game) ) ->
                            let
                                ( game2, maybeAction ) =
                                    WordSpellingGame.updateGame
                                        time
                                        currentUserId
                                        setup
                                        cache
                                        wordSpellingGameMsg
                                        game
                            in
                            ( { model | startedGames = SeqDict.insert matchId (WordSpellingGame_Game game2) model.startedGames }
                            , case maybeAction of
                                Just action ->
                                    [ OutLocalChange (LocalChange_WordSpellingGame matchId (WordSpellingGame.Action action)) ]

                                Nothing ->
                                    []
                            )

                        _ ->
                            ( model, [] )

                _ ->
                    ( model, [] )

        WordSpellingSetupMsg wordSpellingGameMsg ->
            let
                ( model2, maybeSetup ) =
                    WordSpellingGame.updateSetup
                        time
                        currentUserId
                        wordSpellingGameMsg
                        (case model.setup of
                            WordSpellingGame_Setup setup ->
                                setup

                            _ ->
                                WordSpellingGame.initSetup
                        )
            in
            ( case model2 of
                WordSpellingGame.Setup setup ->
                    { model | setup = WordSpellingGame_Setup setup }

                WordSpellingGame.Game game ->
                    { model | startedGames = SeqDict.insert newMatchId (WordSpellingGame_Game game) model.startedGames }
            , case maybeSetup of
                Just setup ->
                    -- A brand new match takes the next message id, then we navigate to it.
                    [ OutLocalChange (LocalChange_WordSpellingGame newMatchId (WordSpellingGame.StartMatch time setup))
                    , OutSelectMatch (Just newMatchId)
                    ]

                Nothing ->
                    []
            )

        PressedSelectGame game ->
            case game of
                GameType_Go ->
                    ( { model | setup = GoModel_Setup Go.initSetup }, [] )

                GameType_WordSpellingGame ->
                    ( { model | setup = WordSpellingGame_Setup WordSpellingGame.initSetup }, [] )

        PressedReset ->
            ( { model | setup = GameSelect }, [ OutSelectMatch Nothing ] )

        SelectedMatch selectedMatchId ->
            ( model, [ OutSelectMatch (Just selectedMatchId) ] )

        NoOpMsg ->
            ( model, [] )


dragStart :
    Time.Posix
    -> Coord CssPixels
    -> NonemptyDict Int Touch
    -> Id ChannelMessageId
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Model
    -> Model
dragStart time windowSize touches matchId matchData model =
    case SeqDict.get matchId matchData of
        Just (MatchData matchData2) ->
            { model
                | startedGames =
                    SeqDict.updateIfExists
                        matchId
                        (\game ->
                            case matchData2.data of
                                FrontendGameData_Go setup _ shared ->
                                    case game of
                                        GoModel_Game game2 ->
                                            Go.dragStart game2 |> GoModel_Game

                                        _ ->
                                            game

                                FrontendGameData_WordSpellingGame setup _ shared ->
                                    case game of
                                        WordSpellingGame_Game game2 ->
                                            WordSpellingGame.dragStart time windowSize touches setup game2
                                                |> WordSpellingGame_Game

                                        _ ->
                                            game
                        )
                        model.startedGames
            }

        Nothing ->
            model


dragEnd :
    Time.Posix
    -> Coord CssPixels
    -> NonemptyDict Int Touch
    -> Id ChannelMessageId
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Model
    -> Model
dragEnd time windowSize touches matchId matchData model =
    case SeqDict.get matchId matchData of
        Just (MatchData matchData2) ->
            { model
                | startedGames =
                    SeqDict.updateIfExists
                        matchId
                        (\game ->
                            case matchData2.data of
                                FrontendGameData_Go setup _ shared ->
                                    case game of
                                        GoModel_Game game2 ->
                                            Go.dragEnd game2 |> GoModel_Game

                                        _ ->
                                            game

                                FrontendGameData_WordSpellingGame setup _ shared ->
                                    case game of
                                        WordSpellingGame_Game game2 ->
                                            WordSpellingGame.dragEnd
                                                time
                                                windowSize
                                                touches
                                                setup
                                                shared
                                                game2
                                                |> WordSpellingGame_Game

                                        _ ->
                                            game
                        )
                        model.startedGames
            }

        Nothing ->
            model


view :
    Time.Posix
    -> Coord CssPixels
    -> Maybe (NonemptyDict Int Touch)
    -> Maybe MyUi.LastCopy
    -> LocalUser
    -> Id UserId
    -> Maybe (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Model
    -> Element Msg
view currentTime windowSize maybeDragging lastCopied localUser otherUserId maybeMatchId matches model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    case maybeMatchId of
        Just matchId ->
            case ( SeqDict.get matchId matches, SeqDict.get matchId model.startedGames ) of
                ( Just (MatchData match), Just game ) ->
                    case match.data of
                        FrontendGameData_Go setup _ cache ->
                            case game of
                                GoModel_Game game2 ->
                                    Ui.column
                                        [ Ui.height (Ui.px (Go.viewHeight windowSize))
                                        , Ui.scrollable
                                        , Ui.background MyUi.tabBackground
                                        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
                                        , Ui.borderColor MyUi.border2
                                        , MyUi.noShrinking
                                        , Ui.spacing 8
                                        ]
                                        [ Ui.el [ Ui.padding 8 ] (goShareView lastCopied matchId match.publicLink)
                                        , Go.gameView
                                            currentTime
                                            windowSize
                                            localUser
                                            setup
                                            cache
                                            game2
                                            |> Ui.map GoGameMsg
                                        ]

                                _ ->
                                    matchNotFound

                        FrontendGameData_WordSpellingGame setup actions cache ->
                            case game of
                                WordSpellingGame_Game game2 ->
                                    WordSpellingGame.gameView
                                        currentTime
                                        windowSize
                                        maybeDragging
                                        (localUser.session.userId == otherUserId)
                                        localUser
                                        setup
                                        actions
                                        cache
                                        game2
                                        |> Ui.map WordSpellingGameMsg

                                _ ->
                                    matchNotFound

                _ ->
                    matchNotFound

        Nothing ->
            Ui.column
                [ Ui.height (Ui.px (Go.viewHeight windowSize))
                , Ui.scrollable
                , Ui.background MyUi.tabBackground
                , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
                , Ui.borderColor MyUi.border2
                , MyUi.noShrinking
                ]
                [ Ui.Lazy.lazy3 matchSwitcherView isMobile maybeMatchId matches
                , case model.setup of
                    GoModel_Setup setup ->
                        Go.setupView (localUser.session.userId == otherUserId) windowSize setup |> Ui.map GoSetupMsg

                    WordSpellingGame_Setup setup ->
                        WordSpellingGame.setupView windowSize setup |> Ui.map WordSpellingSetupMsg

                    GameSelect ->
                        Ui.row
                            [ Ui.spacing 8, Ui.wrap, Ui.padding 8 ]
                            (List.map gameSelectButton allGames)
                ]


matchNotFound : Element msg
matchNotFound =
    Ui.el [ Ui.centerX, Ui.centerY, Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Match not found")


{-| Share controls for the match currently being viewed. Shows a "Share" button that creates a
public link, or, once the link exists, a copyable box with the link.
-}
goShareView : Maybe MyUi.LastCopy -> Id ChannelMessageId -> Maybe (SecretId GamePublicId) -> Element Msg
goShareView lastCopied matchId maybePublicLink =
    Ui.row
        [ Ui.spacing 4, Ui.width Ui.shrink ]
        (case maybePublicLink of
            Just publicLink ->
                [ Ui.text "Share"
                , MyUi.copyBox
                    (Dom.id "go_shareLink")
                    PressedCopyLink
                    NoOpMsg
                    { lastCopied = lastCopied }
                    (Go.publicGoMatchUrl publicLink)
                ]

            Nothing ->
                [ MyUi.simpleButton
                    (Dom.id "go_share")
                    (PressedShareMatch matchId)
                    (Ui.text "Share")
                ]
        )


allGames : List GameType
allGames =
    [ GameType_Go
    , GameType_WordSpellingGame
    ]


gameToString : GameType -> String
gameToString game =
    case game of
        GameType_Go ->
            "Go"

        GameType_WordSpellingGame ->
            "Word Spelling Game"


gameSelectButton : GameType -> Element Msg
gameSelectButton game =
    MyUi.elButton
        (Dom.id ("game_select_" ++ gameToString game))
        (PressedSelectGame game)
        [ Ui.width (Ui.px 200)
        , Ui.height (Ui.px 200)
        , Ui.rounded 8
        , Ui.background MyUi.buttonBackground
        , Ui.border 1
        , Ui.borderColor MyUi.buttonBorder
        , Ui.contentCenterY
        , Ui.Font.size 20
        , Ui.Font.center
        , Ui.Font.bold
        , Ui.padding 16
        ]
        (gameToString game |> Ui.text)


matchSwitcherView : Bool -> Maybe (Id ChannelMessageId) -> SeqDict (Id ChannelMessageId) MatchData -> Element Msg
matchSwitcherView isMobile maybeMatchId matches =
    if SeqDict.isEmpty matches then
        Ui.none

    else
        let
            newMatchValue : String
            newMatchValue =
                " "

            currentValue : String
            currentValue =
                case maybeMatchId of
                    Just matchId ->
                        String.fromInt (Id.toInt matchId)

                    Nothing ->
                        newMatchValue

            onSelect : String -> Msg
            onSelect text =
                if text == newMatchValue then
                    PressedReset

                else
                    case String.toInt text of
                        Just n ->
                            SelectedMatch (Id.fromInt n)

                        Nothing ->
                            PressedReset
        in
        Ui.column
            [ Ui.padding
                (if isMobile then
                    8

                 else
                    12
                )
            , Ui.spacing 8
            , Ui.height (Ui.px MyUi.matchSwitcherHeight)
            ]
            [ Ui.row
                [ Ui.spacing 8
                ]
                [ Ui.el [ Ui.Font.weight 600, Ui.width Ui.shrink ] (Ui.text "View match")
                , Ui.html
                    (Html.select
                        [ Html.Attributes.id "go_matchSwitcher"
                        , Html.Attributes.value currentValue
                        , Html.Events.onInput onSelect
                        , Html.Attributes.style "height" "100%"
                        , Html.Attributes.attribute "aria-label" "View match"
                        , Html.Attributes.style "padding"
                            (if isMobile then
                                "4px"

                             else
                                "7px 8px"
                            )
                        , Html.Attributes.style "border" "1px solid rgb(97,104,124)"
                        , Html.Attributes.style "border-radius" "4px"
                        , Html.Attributes.style "font-size"
                            (if isMobile then
                                "14px"

                             else
                                "16px"
                            )
                        , Html.Attributes.style "background-color" "rgb(32,40,70)"
                        , Html.Attributes.style "color" "rgb(255,255,255)"
                        , Html.Attributes.style "cursor" "pointer"
                        ]
                        (Html.option
                            [ Html.Attributes.value newMatchValue
                            , Html.Attributes.selected (maybeMatchId == Nothing)
                            ]
                            [ Html.text "Setup new match" ]
                            :: List.map
                                (\( matchId, _ ) ->
                                    let
                                        value : String
                                        value =
                                            Id.toString matchId
                                    in
                                    Html.option
                                        [ Html.Attributes.value value
                                        , Html.Attributes.selected (Just matchId == maybeMatchId)
                                        ]
                                        [ Html.text ("Match #" ++ value) ]
                                )
                                (SeqDict.toList matches)
                        )
                    )
                , MyUi.simpleButton (Dom.id "go_reset") PressedReset (Ui.text "New game")
                ]
            , Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border1 ] Ui.none
            ]


pressedKey : Id ChannelMessageId -> String -> SeqDict (Id ChannelMessageId) MatchData -> Maybe Model -> Maybe Model
pressedKey matchId key matchData maybeGameModel =
    let
        model : Model
        model =
            Maybe.withDefault initModel maybeGameModel
    in
    case SeqDict.get matchId matchData of
        Just (MatchData matchData2) ->
            { model
                | startedGames =
                    SeqDict.updateIfExists
                        matchId
                        (\game ->
                            case matchData2.data of
                                FrontendGameData_Go setup _ shared ->
                                    case game of
                                        GoModel_Game game2 ->
                                            Go.pressedKey key shared game2
                                                |> GoModel_Game

                                        _ ->
                                            game

                                FrontendGameData_WordSpellingGame _ _ shared ->
                                    case game of
                                        WordSpellingGame_Game game2 ->
                                            WordSpellingGame.pressedKey game2
                                                |> WordSpellingGame_Game

                                        _ ->
                                            game
                        )
                        model.startedGames
            }
                |> Just

        Nothing ->
            maybeGameModel


gameChangeFromServer : Time.Posix -> LocalChange -> Maybe Model -> Maybe Model
gameChangeFromServer time gameChange maybeModel =
    let
        model : Model
        model =
            Maybe.withDefault initModel maybeModel
    in
    (case gameChange of
        LocalChange_Go matchId goChange ->
            case goChange of
                Go.StartMatch _ _ ->
                    { model | startedGames = SeqDict.insert matchId (GoModel_Game Go.initGame) model.startedGames }

                Go.Action actionWithTime ->
                    let
                        playPop : Bool
                        playPop =
                            case actionWithTime.change of
                                Go.PlaceStone _ _ ->
                                    True

                                Go.PassTurn ->
                                    True

                                Go.MarkTerritory _ _ ->
                                    False

                                Go.FinishedMarking ->
                                    True

                                Go.AcceptTerritory ->
                                    True

                                Go.RejectTerritory ->
                                    True
                    in
                    if playPop then
                        { model
                            | startedGames =
                                SeqDict.updateIfExists
                                    matchId
                                    (\game ->
                                        case game of
                                            GoModel_Game goModel ->
                                                GoModel_Game { goModel | lastPlacedStone = Just time }

                                            _ ->
                                                game
                                    )
                                    model.startedGames
                        }

                    else
                        model

        CreatePublicLink _ _ ->
            model

        LocalChange_WordSpellingGame matchId wordSpellinGameChange ->
            case wordSpellinGameChange of
                WordSpellingGame.StartMatch serverTime setup ->
                    { model
                        | startedGames =
                            SeqDict.insert
                                matchId
                                (WordSpellingGame_Game (WordSpellingGame.initGame serverTime setup))
                                model.startedGames
                    }

                WordSpellingGame.Action action ->
                    case action.change of
                        WordSpellingGame.PlaceWord placedWord _ ->
                            { model
                                | startedGames =
                                    SeqDict.updateIfExists
                                        matchId
                                        (\game ->
                                            case game of
                                                WordSpellingGame_Game gameData ->
                                                    WordSpellingGame_Game
                                                        { gameData
                                                            | lastWordPlaced =
                                                                { time = time
                                                                , letterCount = List.Nonempty.length placedWord.letters
                                                                }
                                                                    |> Just
                                                        }

                                                _ ->
                                                    game
                                        )
                                        model.startedGames
                            }

                        _ ->
                            model
    )
        |> Just
