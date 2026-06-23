module Game exposing
    ( BackendGameData(..)
    , FrontendGameData
    , LocalChange(..)
    , MatchData
    , Model(..)
    , Msg(..)
    , OutMsg(..)
    , addGoAction
    , addPublicLink
    , goMatchData
    , hasPendingTurn
    , initMatchData
    , update
    , view
    )

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom
import Effect.Command as Command
import Effect.Time as Time
import Go
import Html
import Html.Attributes
import Html.Events
import Id exposing (ChannelMessageId, GamePublicId, Id, UserId)
import Message exposing (Game(..))
import MyUi
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import Ui.Lazy
import User exposing (LocalUser)
import UserSession exposing (ToBeFilledInByBackend(..))
import WordSpellingGame


type Model
    = GoModel Go.Model
    | WordSpellingGameModel WordSpellingGame.Model


type BackendGameData
    = GameData_Go Go.ValidatedSetup (Array Go.ActionWithTime)
    | GameData_WordSpellingGame WordSpellingGame.ValidatedSetup (Array WordSpellingGame.ActionWithTime)


type FrontendGameData
    = FrontendGameData_Go Go.ValidatedSetup (Array Go.ActionWithTime) Go.GameState
    | FrontendGameData_WordSpellingGame WordSpellingGame.ValidatedSetup (Array WordSpellingGame.ActionWithTime) WordSpellingGame.GameState


type Msg
    = GoMsg Go.Msg
    | WordSpellingGameMsg WordSpellingGame.Msg
    | PressedShareMatch (Id ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Id ChannelMessageId)
    | PressedReset
    | PressedSelectGame Game


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


initMatchData : BackendGameData -> Maybe (SecretId GamePublicId) -> MatchData
initMatchData gameData publicLink =
    { data =
        case gameData of
            GameData_Go setup actions ->
                FrontendGameData_Go setup actions (Go.foldActions setup actions)

            GameData_WordSpellingGame setup actions ->
                FrontendGameData_WordSpellingGame setup actions (WordSpellingGame.foldActions setup actions)
    , publicLink = publicLink
    }
        |> MatchData


{-| Extract the Go setup and current game state from a match, if it is a Go match.
-}
goMatchData : MatchData -> Maybe ( Go.ValidatedSetup, Go.GameState )
goMatchData (MatchData match) =
    case match.data of
        FrontendGameData_Go setup _ state ->
            Just ( setup, state )

        FrontendGameData_WordSpellingGame _ _ _ ->
            Nothing


addGoAction : Go.ActionWithTime -> MatchData -> MatchData
addGoAction action (MatchData match) =
    { match
        | data =
            case match.data of
                FrontendGameData_Go setup actions cache ->
                    FrontendGameData_Go setup (Array.push action actions) (Go.updateAction setup action cache)

                FrontendGameData_WordSpellingGame setup actions cache ->
                    match.data

        --FrontendGameData_WordSpellingGame setup (Array.push action actions) (WordSpellingGame.updateAction setup action cache)
    }
        |> MatchData


hasPendingTurn : Id UserId -> SeqDict (Id ChannelMessageId) MatchData -> SeqSet (Id ChannelMessageId)
hasPendingTurn userId matches =
    SeqDict.foldl
        (\matchId (MatchData match) set ->
            case match.data of
                FrontendGameData_Go setup actions cache ->
                    case cache.phase of
                        Go.Scored _ ->
                            set

                        _ ->
                            if Go.isLocalUsersTurn userId setup cache then
                                SeqSet.insert matchId set

                            else
                                set

                FrontendGameData_WordSpellingGame _ _ _ ->
                    set
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
    | PlaySound String
    | OutSelectMatch (Maybe (Id ChannelMessageId))


update :
    Time.Posix
    -> Id UserId
    -> Id UserId
    -> Msg
    -> Id ChannelMessageId
    -> Maybe ( Id ChannelMessageId, Go.ValidatedSetup, Go.GameState )
    -> Maybe Model
    -> ( Maybe Model, List OutMsg )
update time currentUserId otherUserId msg newMatchId maybeMatch model =
    case msg of
        PressedShareMatch matchId ->
            ( model, [ OutLocalChange (CreatePublicLink matchId EmptyPlaceholder) ] )

        PressedCopyLink text ->
            ( model, [ CopyText text ] )

        GoMsg goMsg ->
            let
                ( goModel, outMsgs ) =
                    Go.update time
                        currentUserId
                        otherUserId
                        goMsg
                        maybeMatch
                        (case model of
                            Just (GoModel goModel2) ->
                                Just goModel2

                            _ ->
                                Nothing
                        )

                matchId : Id ChannelMessageId
                matchId =
                    case maybeMatch of
                        Just ( id, _, _ ) ->
                            id

                        Nothing ->
                            newMatchId
            in
            ( Maybe.map GoModel goModel
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

                        Go.PlaySound sound ->
                            [ PlaySound sound ]
                )
                outMsgs
            )

        WordSpellingGameMsg wordSpellingGameMsg ->
            let
                ( wsModel, outMsgs ) =
                    WordSpellingGame.update
                        time
                        currentUserId
                        wordSpellingGameMsg
                        (case model of
                            Just (WordSpellingGameModel gameModel) ->
                                gameModel

                            _ ->
                                WordSpellingGame.Setup WordSpellingGame.initSetup
                        )

                matchId : Id ChannelMessageId
                matchId =
                    case maybeMatch of
                        Just ( id, _, _ ) ->
                            id

                        Nothing ->
                            newMatchId
            in
            ( Maybe.map WordSpellingGameModel wsModel
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

                                _ ->
                                    [ OutLocalChange (LocalChange_WordSpellingGame matchId localChange) ]
                )
                outMsgs
            )

        PressedSelectGame game ->
            case game of
                Game_Go ->
                    ( Just (GoModel (Go.Setup Go.initSetup)), [] )

                Game_WordSpellingGame ->
                    ( Just (WordSpellingGameModel (WordSpellingGame.Setup WordSpellingGame.initSetup)), [] )

        PressedReset ->
            ( Nothing, [ OutSelectMatch Nothing ] )

        SelectedMatch selectedMatchId ->
            ( model, [ OutSelectMatch (Just selectedMatchId) ] )


view :
    Time.Posix
    -> Coord CssPixels
    -> Maybe MyUi.LastCopy
    -> LocalUser
    -> Id UserId
    -> Maybe (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Maybe Model
    -> Element Msg
view currentTime windowSize lastCopied localUser otherUserId maybeMatchId matches model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    Ui.el
        [ Ui.height (Ui.px (Go.viewHeight windowSize))
        , Ui.scrollable
        , Ui.background MyUi.tabBackground
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        , MyUi.noShrinking
        ]
        (Ui.column
            []
            [ Ui.Lazy.lazy4 matchSwitcherView isMobile lastCopied maybeMatchId matches
            , case maybeMatchId of
                Just matchId ->
                    case SeqDict.get matchId matches of
                        Just (MatchData match) ->
                            case match.data of
                                FrontendGameData_Go setup _ state ->
                                    Go.gameView
                                        currentTime
                                        windowSize
                                        localUser
                                        setup
                                        state
                                        (case model of
                                            Just (GoModel (Go.Game game)) ->
                                                game

                                            _ ->
                                                Go.initGame
                                        )
                                        |> Ui.map GoMsg

                                FrontendGameData_WordSpellingGame setup _ cache ->
                                    WordSpellingGame.gameView
                                        localUser.session.userId
                                        setup
                                        cache
                                        (case model of
                                            Just (WordSpellingGameModel (WordSpellingGame.Game game)) ->
                                                game

                                            _ ->
                                                WordSpellingGame.initGame
                                        )
                                        |> Ui.map WordSpellingGameMsg

                        Nothing ->
                            Ui.el [ Ui.centerX, Ui.centerY, Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Match not found")

                Nothing ->
                    case model of
                        Just (GoModel model2) ->
                            Go.setupView
                                (localUser.session.userId == otherUserId)
                                windowSize
                                (case model2 of
                                    Go.Setup setup ->
                                        setup

                                    _ ->
                                        Go.initSetup
                                )
                                |> Ui.map GoMsg

                        Just (WordSpellingGameModel model2) ->
                            WordSpellingGame.setupView
                                windowSize
                                (case model2 of
                                    WordSpellingGame.Setup setup ->
                                        setup

                                    _ ->
                                        WordSpellingGame.initSetup
                                )
                                |> Ui.map WordSpellingGameMsg

                        Nothing ->
                            Ui.row
                                [ Ui.spacing 8, Ui.wrap ]
                                (List.map gameSelectButton allGames)
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
            "Word Spelling Game"


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
        ]
        (gameToString game |> Ui.text)


matchSwitcherView : Bool -> Maybe MyUi.LastCopy -> Maybe (Id ChannelMessageId) -> SeqDict (Id ChannelMessageId) MatchData -> Element Msg
matchSwitcherView isMobile lastCopied maybeMatchId matches =
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
                , case maybeMatchId of
                    Just matchId ->
                        Ui.row
                            [ Ui.spacing 4, Ui.alignRight ]
                            (case SeqDict.get matchId matches of
                                Just (MatchData match) ->
                                    case match.publicLink of
                                        Just publicLink ->
                                            [ Ui.text "Share"
                                            , MyUi.copyBox
                                                (Dom.id "go_shareLink")
                                                PressedCopyLink
                                                (GoMsg Go.NoOpMsg)
                                                { lastCopied = lastCopied }
                                                (Go.publicGoMatchUrl publicLink)
                                            ]

                                        Nothing ->
                                            [ MyUi.simpleButton
                                                (Dom.id "go_share")
                                                (PressedShareMatch matchId)
                                                (Ui.text "Share")
                                            ]

                                Nothing ->
                                    [ MyUi.simpleButton
                                        (Dom.id "go_share")
                                        (PressedShareMatch matchId)
                                        (Ui.text "Share")
                                    ]
                            )

                    Nothing ->
                        Ui.none
                ]
            , Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border1 ] Ui.none
            ]
