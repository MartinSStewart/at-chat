module Game exposing (..)

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Go
import Html
import Html.Attributes
import Html.Events
import Id exposing (ChannelMessageId, GamePublicId, Id, UserId)
import MyUi
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import Ui.Lazy
import User exposing (LocalUser)
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

                FrontendGameData_WordSpellingGame setup array gameState ->
                    Debug.todo ""
        )
        SeqSet.empty
        matches


view :
    Time.Posix
    -> Coord CssPixels
    -> Maybe MyUi.LastCopy
    -> LocalUser
    -> Id UserId
    -> Maybe (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Maybe Model
    -> Element Go.Msg
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
                                        |> Ui.map Go.GameMsg

                                FrontendGameData_WordSpellingGame _ _ _ ->
                                    Ui.text "Unsupported game"

                        Nothing ->
                            Ui.text "Match not found"

                Nothing ->
                    Go.setupView
                        (localUser.session.userId == otherUserId)
                        windowSize
                        (case model of
                            Just (GoModel (Go.Setup setup)) ->
                                setup

                            _ ->
                                Go.initSetup
                        )
                        |> Ui.map Go.SetupMsg
            ]
        )


matchSwitcherView : Bool -> Maybe MyUi.LastCopy -> Maybe (Id ChannelMessageId) -> SeqDict (Id ChannelMessageId) MatchData -> Element Go.Msg
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

            onSelect : String -> Go.Msg
            onSelect text =
                if text == newMatchValue then
                    Go.SelectedMatch Nothing

                else
                    case String.toInt text of
                        Just n ->
                            Go.SelectedMatch (Just (Id.fromInt n))

                        Nothing ->
                            Go.SelectedMatch Nothing
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
                , MyUi.simpleButton (Dom.id "go_reset") Go.PressedReset (Ui.text "New game")
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
                                                Go.PressedCopyLink
                                                Go.NoOpMsg
                                                { lastCopied = lastCopied }
                                                (Go.publicGoMatchUrl publicLink)
                                            ]

                                        Nothing ->
                                            [ MyUi.simpleButton
                                                (Dom.id "go_share")
                                                (Go.PressedShareGoMatch matchId)
                                                (Ui.text "Share")
                                            ]

                                Nothing ->
                                    [ MyUi.simpleButton
                                        (Dom.id "go_share")
                                        (Go.PressedShareGoMatch matchId)
                                        (Ui.text "Share")
                                    ]
                            )

                    Nothing ->
                        Ui.none
                ]
            , Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border1 ] Ui.none
            ]
