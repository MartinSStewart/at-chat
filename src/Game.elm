module Game exposing
    ( BackendGameData(..)
    , FrontendGameData(..)
    , LocalChange(..)
    , MatchData(..)
    , Model(..)
    , Msg(..)
    , OutMsg(..)
    , addGoAction
    , addPublicLink
    , addWordSpellingGameAction
    , audio
    , gameToString
    , goMatchData
    , hasPendingTurn
    , initMatchData
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
import Message exposing (Game(..))
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


type Model
    = GoModel_Setup Go.SetupModel
    | GoModel_Game Go.GameModel
    | WordSpellingGame_Setup WordSpellingGame.SetupModel
    | WordSpellingGame_Game WordSpellingGame.GameData


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
    | PressedSelectGame Game
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


audio : Audio.Source -> Id UserId -> MatchData -> Model -> Audio
audio popSound currentUserId (MatchData matchData) model =
    case matchData.data of
        FrontendGameData_Go _ _ _ ->
            case model of
                GoModel_Game model2 ->
                    Go.audio popSound model2

                _ ->
                    Audio.silence

        FrontendGameData_WordSpellingGame _ _ shared ->
            case model of
                WordSpellingGame_Game model2 ->
                    WordSpellingGame.audio popSound currentUserId shared model2

                _ ->
                    Audio.silence


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


{-| Extract the Go setup and current game state from a match, if it is a Go match.
-}
goMatchData : MatchData -> Maybe ( Go.ValidatedSetup, Go.Shared )
goMatchData (MatchData match) =
    case match.data of
        FrontendGameData_Go setup _ state ->
            Just ( setup, state )

        FrontendGameData_WordSpellingGame _ _ _ ->
            Nothing


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
    -> Maybe Model
    -> ( Maybe Model, List OutMsg )
update time currentUserId otherUserId msg newMatchId maybeMatch model =
    case msg of
        PressedShareMatch matchId ->
            ( model, [ OutLocalChange (CreatePublicLink matchId EmptyPlaceholder) ] )

        PressedCopyLink text ->
            ( model, [ CopyText text ] )

        GoGameMsg goMsg ->
            case maybeMatch of
                Just ( _, MatchData matchData ) ->
                    case matchData.data of
                        FrontendGameData_Go setup _ cache ->
                            let
                                ( goModel, outMsgs ) =
                                    Go.updateGame
                                        time
                                        currentUserId
                                        goMsg
                                        setup
                                        cache
                                        (case model of
                                            Just (GoModel_Game goModel2) ->
                                                goModel2

                                            _ ->
                                                Go.initGame
                                        )

                                matchId : Id ChannelMessageId
                                matchId =
                                    case maybeMatch of
                                        Just ( id, _ ) ->
                                            id

                                        Nothing ->
                                            newMatchId
                            in
                            ( GoModel_Game goModel |> Just
                            , List.concatMap
                                (\outMsg ->
                                    case outMsg of
                                        Go.OutLocalChange localChange ->
                                            case localChange of
                                                Go.StartMatch _ _ ->
                                                    -- A brand new match takes the next message id, then we navigate to it.
                                                    [ OutLocalChange (LocalChange_Go matchId localChange)
                                                    , OutSelectMatch (Just matchId)
                                                    ]

                                                _ ->
                                                    [ OutLocalChange (LocalChange_Go matchId localChange) ]
                                )
                                outMsgs
                            )

                        _ ->
                            ( model, [] )

                Nothing ->
                    ( model, [] )

        GoSetupMsg goMsg ->
            let
                ( goModel, outMsgs ) =
                    Go.updateSetup
                        time
                        currentUserId
                        otherUserId
                        goMsg
                        (case model of
                            Just (GoModel_Setup setup) ->
                                setup

                            _ ->
                                Go.initSetup
                        )

                matchId : Id ChannelMessageId
                matchId =
                    case maybeMatch of
                        Just ( id, _ ) ->
                            id

                        Nothing ->
                            newMatchId
            in
            ( case goModel of
                Go.Setup setup ->
                    GoModel_Setup setup |> Just

                Go.Game gameModel ->
                    GoModel_Game gameModel |> Just
            , List.concatMap
                (\outMsg ->
                    case outMsg of
                        Go.OutLocalChange localChange ->
                            case localChange of
                                Go.StartMatch _ _ ->
                                    -- A brand new match takes the next message id, then we navigate to it.
                                    [ OutLocalChange (LocalChange_Go matchId localChange)
                                    , OutSelectMatch (Just matchId)
                                    ]

                                _ ->
                                    [ OutLocalChange (LocalChange_Go matchId localChange) ]
                )
                outMsgs
            )

        WordSpellingGameMsg wordSpellingGameMsg ->
            case maybeMatch of
                Just ( _, MatchData matchData ) ->
                    case ( matchData.data, model ) of
                        ( FrontendGameData_WordSpellingGame setup _ cache, Just (WordSpellingGame_Game gameModel) ) ->
                            let
                                ( notSharedModel, outMsgs ) =
                                    WordSpellingGame.updateGame
                                        time
                                        currentUserId
                                        setup
                                        cache
                                        wordSpellingGameMsg
                                        gameModel

                                matchId : Id ChannelMessageId
                                matchId =
                                    case maybeMatch of
                                        Just ( id, _ ) ->
                                            id

                                        Nothing ->
                                            newMatchId
                            in
                            ( WordSpellingGame_Game notSharedModel |> Just
                            , List.concatMap
                                (\outMsg ->
                                    case outMsg of
                                        WordSpellingGame.OutLocalChange localChange ->
                                            case localChange of
                                                WordSpellingGame.StartMatch _ _ ->
                                                    -- A brand new match takes the next message id, then we navigate to it.
                                                    [ OutLocalChange (LocalChange_WordSpellingGame matchId localChange)
                                                    , OutSelectMatch (Just matchId)
                                                    ]

                                                WordSpellingGame.Action _ ->
                                                    [ OutLocalChange (LocalChange_WordSpellingGame matchId localChange) ]
                                )
                                outMsgs
                            )

                        _ ->
                            ( model, [] )

                _ ->
                    ( model, [] )

        WordSpellingSetupMsg wordSpellingGameMsg ->
            let
                ( model2, outMsgs ) =
                    WordSpellingGame.updateSetup
                        time
                        currentUserId
                        wordSpellingGameMsg
                        (case model of
                            Just (WordSpellingGame_Setup setup) ->
                                setup

                            _ ->
                                WordSpellingGame.initSetup
                        )

                matchId : Id ChannelMessageId
                matchId =
                    case maybeMatch of
                        Just ( id, _ ) ->
                            id

                        Nothing ->
                            newMatchId
            in
            ( case model2 of
                WordSpellingGame.Setup setup ->
                    WordSpellingGame_Setup setup |> Just

                WordSpellingGame.Game game ->
                    WordSpellingGame_Game game |> Just
            , List.concatMap
                (\outMsg ->
                    case outMsg of
                        WordSpellingGame.OutLocalChange localChange ->
                            case localChange of
                                WordSpellingGame.StartMatch _ _ ->
                                    -- A brand new match takes the next message id, then we navigate to it.
                                    [ OutLocalChange (LocalChange_WordSpellingGame matchId localChange)
                                    , OutSelectMatch (Just matchId)
                                    ]

                                WordSpellingGame.Action _ ->
                                    [ OutLocalChange (LocalChange_WordSpellingGame matchId localChange) ]
                )
                outMsgs
            )

        PressedSelectGame game ->
            case game of
                Game_Go ->
                    ( Just (GoModel_Setup Go.initSetup), [] )

                Game_WordSpellingGame ->
                    ( Just (WordSpellingGame_Setup WordSpellingGame.initSetup), [] )

        PressedReset ->
            ( Nothing, [ OutSelectMatch Nothing ] )

        SelectedMatch selectedMatchId ->
            ( model, [ OutSelectMatch (Just selectedMatchId) ] )

        NoOpMsg ->
            ( model, [] )


view :
    Time.Posix
    -> Coord CssPixels
    -> Maybe (NonemptyDict Int Touch)
    -> Maybe MyUi.LastCopy
    -> LocalUser
    -> Id UserId
    -> Maybe (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Maybe Model
    -> Element Msg
view currentTime windowSize maybeDragging lastCopied localUser otherUserId maybeMatchId matches model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    case maybeMatchId of
        Just matchId ->
            case SeqDict.get matchId matches of
                Just (MatchData match) ->
                    case match.data of
                        FrontendGameData_Go setup _ cache ->
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
                                    (case model of
                                        Just (GoModel_Game game) ->
                                            game

                                        _ ->
                                            Go.initGame
                                    )
                                    |> Ui.map GoGameMsg
                                ]

                        FrontendGameData_WordSpellingGame setup actions cache ->
                            case model of
                                Just (WordSpellingGame_Game game) ->
                                    WordSpellingGame.gameView
                                        currentTime
                                        windowSize
                                        maybeDragging
                                        localUser
                                        setup
                                        actions
                                        cache
                                        game
                                        |> Ui.map WordSpellingGameMsg

                                _ ->
                                    matchNotFound

                Nothing ->
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
                , case model of
                    Just (GoModel_Game _) ->
                        Go.setupView (localUser.session.userId == otherUserId) windowSize Go.initSetup |> Ui.map GoSetupMsg

                    Just (GoModel_Setup setup) ->
                        Go.setupView (localUser.session.userId == otherUserId) windowSize setup |> Ui.map GoSetupMsg

                    Just (WordSpellingGame_Game _) ->
                        WordSpellingGame.setupView windowSize WordSpellingGame.initSetup |> Ui.map WordSpellingSetupMsg

                    Just (WordSpellingGame_Setup setup) ->
                        WordSpellingGame.setupView windowSize setup |> Ui.map WordSpellingSetupMsg

                    Nothing ->
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


allGames : List Game
allGames =
    [ Game_Go
    , Game_WordSpellingGame
    ]


gameToString : Game -> String
gameToString game =
    case game of
        Game_Go ->
            "Go"

        Game_WordSpellingGame ->
            "Word Spelling Game (WIP)"


gameSelectButton : Game -> Element Msg
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
