module Game exposing
    ( BackendGameData(..)
    , FrontendGameData(..)
    , Game(..)
    , LoadedMatch
    , LocalChange(..)
    , MatchData(..)
    , Model
    , Msg(..)
    , OutMsg(..)
    , Setup(..)
    , addGoAction
    , addPublicLink
    , addSheepGameAction
    , addWordSpellingGameAction
    , audio
    , dragEnd
    , dragStart
    , gameChangeFromServer
    , gameToString
    , initMatchData
    , initModel
    , insideBoard
    , isAnimating
    , isNotLoaded
    , matchNotLoaded
    , pressedKey
    , routeRequest
    , sheepGameAnswerSaveDelay
    , sheepGameFileUploaded
    , sheepGameFilesToAttach
    , sheepGameQuestionsSaveDelay
    , update
    , view
    , wordSpellingScrollPosition
    )

import Array exposing (Array)
import Audio exposing (Audio)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.File exposing (File)
import Effect.Http as Http
import Effect.Time as Time
import FileStatus exposing (FileId)
import Go
import Html
import Html.Attributes
import Html.Events
import Id exposing (ChannelMessageId, GamePublicId, GuildOrDmId(..), Id, UserId)
import IdArray
import List.Nonempty exposing (Nonempty)
import Message exposing (GameType(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import Scroll
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SheepGame
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Font
import Ui.Lazy
import Ui.Shadow
import User exposing (LocalUser)
import UserSession exposing (ToBeFilledInByBackend(..))
import WordSpellingGame


type alias Model =
    { startedGames : SeqDict (Id ChannelMessageId) Game
    , setup : Setup
    , -- Bumped every time the sheep game questions change. The save that runs a moment
      -- later only goes ahead if the count still matches, so a burst of typing costs one
      -- request instead of one per keystroke.
      sheepGameQuestionsCounter : Int
    , -- The same idea, one count per answer box, so that typing an answer to one question
      -- doesn't cancel the save another question's answer was waiting on.
      sheepGameAnswerCounters : SeqDict ( Id ChannelMessageId, Id SheepGame.QuestionId ) Int
    }


type Game
    = GoModel_Game Go.GameModel
    | WordSpellingGame_Game WordSpellingGame.GameData
    | SheepGame_Game SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Go.SetupModel
    | WordSpellingGame_Setup WordSpellingGame.SetupModel
    | SheepGame_Setup SheepGame.SetupModel


type BackendGameData
    = GameData_Go Go.ValidatedSetup (Array Go.ActionWithTime)
    | GameData_WordSpellingGame WordSpellingGame.ValidatedSetup (Array WordSpellingGame.ActionWithTime) WordSpellingGame.Shared
    | GameData_SheepGame SheepGame.ValidatedSetup (Array SheepGame.ActionWithTime) SheepGame.Shared


{-| OpaqueVariants
-}
type FrontendGameData
    = FrontendGameData_Go Go.ValidatedSetup (Array Go.ActionWithTime) Go.Shared
    | FrontendGameData_WordSpellingGame WordSpellingGame.ValidatedSetup (Array WordSpellingGame.ActionWithTime) WordSpellingGame.Shared
    | FrontendGameData_SheepGame SheepGame.ValidatedSetup (Array SheepGame.ActionWithTime) SheepGame.Shared


type Msg
    = GoGameMsg Go.GameMsg
    | GoSetupMsg Go.SetupMsg
    | WordSpellingGameMsg WordSpellingGame.GameMsg
    | WordSpellingSetupMsg WordSpellingGame.SetupMsg
    | SheepGameMsg SheepGame.GameMsg
    | SheepSetupMsg SheepGame.SetupMsg
    | PressedShareMatch (Id ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Id ChannelMessageId)
    | PressedReset
    | PressedSelectGame GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameAnswerDebounce (Id ChannelMessageId) (Id SheepGame.QuestionId) Int
    | NoOpMsg


{-| OpaqueVariants
-}
type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (SecretId GamePublicId)
        }
    | MatchNotLoaded GameType


addPublicLink : SecretId GamePublicId -> MatchData -> MatchData
addPublicLink publicLink matchData =
    case matchData of
        MatchData matchData2 ->
            { matchData2 | publicLink = Just publicLink } |> MatchData

        MatchNotLoaded _ ->
            matchData


audio : Audio.Source -> Id UserId -> Id ChannelMessageId -> MatchData -> Model -> Audio
audio popSound currentUserId matchId matchData model =
    case matchData of
        MatchData matchData2 ->
            case matchData2.data of
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

                FrontendGameData_SheepGame _ _ _ ->
                    Audio.silence

        MatchNotLoaded _ ->
            Audio.silence


isAnimating : Time.Posix -> Coord CssPixels -> Id ChannelMessageId -> MatchData -> Model -> Bool
isAnimating time windowSize matchId matchData model =
    case matchData of
        MatchData matchData2 ->
            case matchData2.data of
                FrontendGameData_Go _ _ _ ->
                    False

                FrontendGameData_WordSpellingGame _ _ shared ->
                    WordSpellingGame.isAnimating time shared
                        || (case SeqDict.get matchId model.startedGames of
                                Just (WordSpellingGame_Game game) ->
                                    WordSpellingGame.anyTileAnimating time game
                                        || WordSpellingGame.isZoomAnimating time windowSize game

                                _ ->
                                    False
                           )

                FrontendGameData_SheepGame _ _ _ ->
                    False

        MatchNotLoaded _ ->
            False


insideBoard : Coord CssPixels -> Coord CssPixels -> GuildOrDmId -> Id ChannelMessageId -> MatchData -> SeqDict GuildOrDmId Model -> Bool
insideBoard windowSize coord guildOrDmId matchId matchData games =
    case matchData of
        MatchData matchData2 ->
            case matchData2.data of
                FrontendGameData_Go _ _ _ ->
                    False

                FrontendGameData_WordSpellingGame setup _ _ ->
                    case SeqDict.get guildOrDmId games |> Maybe.withDefault initModel |> .startedGames |> SeqDict.get matchId of
                        Just (WordSpellingGame_Game game) ->
                            WordSpellingGame.insideBoard
                                setup
                                game
                                windowSize
                                coord

                        _ ->
                            False

                FrontendGameData_SheepGame _ _ _ ->
                    False

        MatchNotLoaded _ ->
            False


initModel : Model
initModel =
    { setup = GameSelect
    , startedGames = SeqDict.empty
    , sheepGameQuestionsCounter = 0
    , sheepGameAnswerCounters = SeqDict.empty
    }


initMatchData : BackendGameData -> Maybe (SecretId GamePublicId) -> MatchData
initMatchData gameData publicLink =
    { data =
        case gameData of
            GameData_Go setup actions ->
                FrontendGameData_Go setup actions (Go.foldActions setup actions)

            GameData_WordSpellingGame setup actions shared ->
                FrontendGameData_WordSpellingGame setup actions shared

            GameData_SheepGame setup actions shared ->
                FrontendGameData_SheepGame setup actions shared
    , publicLink = publicLink
    }
        |> MatchData


{-| Everything the frontend needs to show a match it has just asked for.
-}
type alias LoadedMatch =
    { gameData : BackendGameData, publicLink : Maybe (SecretId GamePublicId) }


matchNotLoaded : BackendGameData -> MatchData
matchNotLoaded gameData =
    MatchNotLoaded
        (case gameData of
            GameData_Go _ _ ->
                GameType_Go

            GameData_WordSpellingGame _ _ _ ->
                GameType_WordSpellingGame

            GameData_SheepGame _ _ _ ->
                GameType_SheepGame
        )


{-| Whether the backend has only told us this match exists, rather than sending it.
-}
isNotLoaded : MatchData -> Bool
isNotLoaded matchData =
    case matchData of
        MatchData _ ->
            False

        MatchNotLoaded _ ->
            True


addGoAction : Go.ActionWithTime -> MatchData -> MatchData
addGoAction action matchData =
    case matchData of
        MatchData matchData2 ->
            { matchData2
                | data =
                    case matchData2.data of
                        FrontendGameData_Go setup actions cache ->
                            FrontendGameData_Go setup (Array.push action actions) (Go.updateAction setup action cache)

                        _ ->
                            matchData2.data
            }
                |> MatchData

        MatchNotLoaded _ ->
            matchData


{-| How far the Past moves list is scrolled for the given word-spelling match. Frontend uses this to
decide whether a new action should auto-scroll the list to the bottom (see
`WordSpellingGame.recentActionsView`). Defaults to the bottom when the match hasn't been opened yet.
-}
wordSpellingScrollPosition : Id ChannelMessageId -> Model -> Scroll.ScrollPosition
wordSpellingScrollPosition matchId model =
    case SeqDict.get matchId model.startedGames of
        Just (WordSpellingGame_Game gameData) ->
            gameData.scrollPosition

        _ ->
            Scroll.ScrolledToBottom


routeRequest :
    Time.Posix
    -> LocalUser
    -> GuildOrDmId
    -> Id ChannelMessageId
    -> SeqDict (Id ChannelMessageId) MatchData
    -> SeqDict GuildOrDmId Model
    -> SeqDict GuildOrDmId Model
routeRequest time localUser guildOrDmId matchId matchData models =
    let
        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId
    in
    case SeqDict.get matchId matchData of
        Just (MatchData matchData2) ->
            SeqDict.update
                guildOrDmId
                (\maybeModel ->
                    let
                        model =
                            Maybe.withDefault initModel maybeModel
                    in
                    (case matchData2.data of
                        FrontendGameData_Go _ _ _ ->
                            { model
                                | startedGames =
                                    SeqDict.update
                                        matchId
                                        (\maybeGame ->
                                            case maybeGame of
                                                Just _ ->
                                                    maybeGame

                                                Nothing ->
                                                    GoModel_Game Go.initGame |> Just
                                        )
                                        model.startedGames
                            }

                        FrontendGameData_WordSpellingGame setup _ shared ->
                            { model
                                | startedGames =
                                    SeqDict.update
                                        matchId
                                        (\maybeGame ->
                                            case maybeGame of
                                                Just _ ->
                                                    maybeGame

                                                Nothing ->
                                                    WordSpellingGame.initGame time currentUserId setup shared
                                                        |> WordSpellingGame_Game
                                                        |> Just
                                        )
                                        model.startedGames
                            }

                        FrontendGameData_SheepGame setup _ shared ->
                            { model
                                | startedGames =
                                    SeqDict.update
                                        matchId
                                        (\maybeGame ->
                                            case maybeGame of
                                                Just _ ->
                                                    maybeGame

                                                Nothing ->
                                                    SheepGame.initGame localUser setup shared
                                                        |> SheepGame_Game
                                                        |> Just
                                        )
                                        model.startedGames
                            }
                    )
                        |> Just
                )
                models

        Just (MatchNotLoaded _) ->
            models

        Nothing ->
            models


addWordSpellingGameAction : WordSpellingGame.ActionWithTime -> MatchData -> MatchData
addWordSpellingGameAction action matchData =
    case matchData of
        MatchData matchData2 ->
            { matchData2
                | data =
                    case matchData2.data of
                        FrontendGameData_Go _ _ _ ->
                            matchData2.data

                        FrontendGameData_WordSpellingGame setup actions cache ->
                            FrontendGameData_WordSpellingGame
                                setup
                                (Array.push action actions)
                                (WordSpellingGame.updateAction setup action cache |> Tuple.first)

                        _ ->
                            matchData2.data
            }
                |> MatchData

        MatchNotLoaded _ ->
            matchData


addSheepGameAction : SheepGame.ActionWithTime -> MatchData -> MatchData
addSheepGameAction action matchData =
    case matchData of
        MatchData matchData2 ->
            { matchData2
                | data =
                    case matchData2.data of
                        FrontendGameData_SheepGame setup actions cache ->
                            FrontendGameData_SheepGame
                                setup
                                (Array.push action actions)
                                (SheepGame.updateAction setup action cache)

                        _ ->
                            matchData2.data
            }
                |> MatchData

        MatchNotLoaded _ ->
            matchData


type LocalChange
    = CreatePublicLink (Id ChannelMessageId) (ToBeFilledInByBackend (SecretId GamePublicId))
      -- Ask the backend for a match it only told us the existence of. Matches are sent as
      -- `MatchNotLoaded` until someone opens one, so that a channel with a lot of finished
      -- games costs nothing to load.
    | LoadMatch (Id ChannelMessageId) (ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Id ChannelMessageId) Go.LocalChange
    | LocalChange_WordSpellingGame (Id ChannelMessageId) WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Id ChannelMessageId) SheepGame.LocalChange


type OutMsg
    = OutLocalChange LocalChange
    | CopyText String
    | OutSelectMatch (Maybe (Id ChannelMessageId))
    | ScrollToBottom HtmlId
      -- Fetch the dictionary definition for an English word the player clicked in a Word Spelling
      -- Game's Moves log. The frontend issues the HTTP request (see `Frontend.handleGameOutMsgs`).
    | FetchWordDefinition String
      -- Hold onto the sheep game questions the host has written so far, so that a refresh
      -- in the middle of setting a game up doesn't throw them away.
    | SaveSheepGameQuestions (Array UserSession.SheepGameQuestion)
      -- Ask to be sent `CheckedSheepGameQuestionsDebounce` once the host has stopped typing
      -- (see `Frontend.handleGameOutMsgs`).
    | SaveSheepGameQuestionsAfterDelay Int
      -- Ask to be sent `CheckedSheepGameAnswerDebounce` once the player has stopped typing
      -- their answer to that question (see `Frontend.handleGameOutMsgs`).
    | SaveSheepGameAnswerAfterDelay (Id ChannelMessageId) (Id SheepGame.QuestionId) Int
    | OpenSheepGameEmojiSelector SheepGame.Input
      -- Ask for a file to attach to a sheep game question, then upload what comes back
      -- (see `Frontend.handleGameOutMsgs`).
    | SelectSheepGameFilesToAttach SheepGame.Input
    | UploadSheepGameAttachedFiles SheepGame.Input (Nonempty ( Id FileId, File ))
    | CancelSheepGameAttachedFileUpload SheepGame.Input (Id FileId)
      -- Show what a file the host attached to a sheep game question holds. Where that's
      -- drawn belongs to the frontend rather than to the game.
    | ShowSheepGameAttachedFileInfo FileStatus.FileDataWithImage


update :
    Time.Posix
    -> Coord CssPixels
    -> LocalUser
    -> GuildOrDmId
    -> Msg
    -> Id ChannelMessageId
    -> Maybe ( Id ChannelMessageId, MatchData )
    -> Model
    -> ( Model, List OutMsg )
update time windowSize localUser guildOrDmId msg newMatchId maybeMatch model =
    let
        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId
    in
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

                Just ( _, MatchNotLoaded _ ) ->
                    ( model, [] )

                Nothing ->
                    ( model, [] )

        GoSetupMsg goMsg ->
            let
                ( goModel, maybeStartMatch ) =
                    Go.updateSetup
                        currentUserId
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

                Go.CancelSetup ->
                    { model | setup = GameSelect }
            , case maybeStartMatch of
                Just setup ->
                    -- A brand new match takes the next message id, then we navigate to it.
                    (if GuildOrDmId_Dm { otherUserId = currentUserId } == guildOrDmId then
                        [ OutLocalChange (LocalChange_Go newMatchId (Go.Action { time = time, change = Go.Joined currentUserId })) ]

                     else
                        []
                    )
                        ++ [ OutLocalChange (LocalChange_Go newMatchId (Go.StartMatch time setup))
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
                                ( game2, maybeAction, maybeFetchDefinition ) =
                                    WordSpellingGame.updateGame
                                        time
                                        windowSize
                                        currentUserId
                                        setup
                                        cache
                                        wordSpellingGameMsg
                                        game
                            in
                            ( { model | startedGames = SeqDict.insert matchId (WordSpellingGame_Game game2) model.startedGames }
                            , (case maybeAction of
                                Just action ->
                                    [ OutLocalChange
                                        (LocalChange_WordSpellingGame
                                            matchId
                                            (WordSpellingGame.Action { userId = currentUserId, time = time, change = action })
                                        )
                                    , ScrollToBottom WordSpellingGame.pastWordsContainerId
                                    ]

                                Nothing ->
                                    []
                              )
                                ++ (case maybeFetchDefinition of
                                        Just word ->
                                            [ FetchWordDefinition word ]

                                        Nothing ->
                                            []
                                   )
                            )

                        _ ->
                            ( model, [] )

                Just ( _, MatchNotLoaded _ ) ->
                    ( model, [] )

                Nothing ->
                    ( model, [] )

        WordSpellingSetupMsg wordSpellingGameMsg ->
            let
                ( gameOrSetup, maybeSetup ) =
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
            ( case gameOrSetup of
                WordSpellingGame.Setup setup ->
                    { model | setup = WordSpellingGame_Setup setup }

                WordSpellingGame.Game game ->
                    { model | startedGames = SeqDict.insert newMatchId (WordSpellingGame_Game game) model.startedGames }

                WordSpellingGame.CancelSetup ->
                    { model | setup = GameSelect }
            , case maybeSetup of
                Just setup ->
                    -- A brand new match takes the next message id, then we navigate to it.
                    [ OutLocalChange (LocalChange_WordSpellingGame newMatchId (WordSpellingGame.StartMatch time setup))
                    , OutSelectMatch (Just newMatchId)
                    ]

                Nothing ->
                    []
            )

        SheepGameMsg sheepMsg ->
            case maybeMatch of
                Just ( matchId, MatchData matchData ) ->
                    case ( matchData.data, SeqDict.get matchId model.startedGames ) of
                        ( FrontendGameData_SheepGame setup _ cache, Just (SheepGame_Game oldGame) ) ->
                            let
                                ( game, maybeAction, outMsg ) =
                                    SheepGame.updateGame localUser setup cache sheepMsg oldGame

                                -- An answer is saved a moment after the player stops typing it,
                                -- so nothing is lost to a refresh and there's no button to press.
                                changed : List (Id SheepGame.QuestionId)
                                changed =
                                    SheepGame.changedAnswers oldGame game

                                counters : SeqDict ( Id ChannelMessageId, Id SheepGame.QuestionId ) Int
                                counters =
                                    List.foldl
                                        (\questionId dict ->
                                            SeqDict.update
                                                ( matchId, questionId )
                                                (\count -> Maybe.withDefault 0 count + 1 |> Just)
                                                dict
                                        )
                                        model.sheepGameAnswerCounters
                                        changed
                            in
                            ( { model
                                | startedGames = SeqDict.insert matchId (SheepGame_Game game) model.startedGames
                                , sheepGameAnswerCounters = counters
                              }
                            , (case maybeAction of
                                Just action ->
                                    [ OutLocalChange
                                        (LocalChange_SheepGame
                                            matchId
                                            (SheepGame.Action { userId = currentUserId, time = time, change = action })
                                        )
                                    ]

                                Nothing ->
                                    []
                              )
                                ++ List.map
                                    (\questionId ->
                                        SeqDict.get ( matchId, questionId ) counters
                                            |> Maybe.withDefault 0
                                            |> SaveSheepGameAnswerAfterDelay matchId questionId
                                    )
                                    changed
                                ++ sheepGameOutMsgs time newMatchId outMsg
                            )

                        _ ->
                            ( model, [] )

                Just ( _, MatchNotLoaded _ ) ->
                    ( model, [] )

                Nothing ->
                    ( model, [] )

        SheepSetupMsg sheepMsg ->
            let
                oldSetup : SheepGame.SetupModel
                oldSetup =
                    case model.setup of
                        SheepGame_Setup setup ->
                            setup

                        _ ->
                            SheepGame.initSetup

                ( gameOrSetup, outMsg ) =
                    SheepGame.updateSetup localUser sheepMsg oldSetup

                outMsg2 : List OutMsg
                outMsg2 =
                    sheepGameOutMsgs time newMatchId outMsg
            in
            case gameOrSetup of
                SheepGame.Setup setup ->
                    if setup.questions == oldSetup.questions then
                        ( { model | setup = SheepGame_Setup setup }, outMsg2 )

                    else
                        ( { model
                            | setup = SheepGame_Setup setup
                            , sheepGameQuestionsCounter = model.sheepGameQuestionsCounter + 1
                          }
                        , SaveSheepGameQuestionsAfterDelay (model.sheepGameQuestionsCounter + 1) :: outMsg2
                        )

                SheepGame.Game game ->
                    -- The questions are part of the match now, so the copy that was being held
                    -- onto for the setup view isn't worth keeping. Bumping the counter stops a
                    -- save that typing already scheduled from writing them back afterwards.
                    ( { model
                        | startedGames = SeqDict.insert newMatchId (SheepGame_Game game) model.startedGames
                        , sheepGameQuestionsCounter = model.sheepGameQuestionsCounter + 1
                      }
                    , SaveSheepGameQuestions Array.empty :: outMsg2
                    )

                SheepGame.CancelSetup ->
                    ( { model
                        | setup = GameSelect
                        , sheepGameQuestionsCounter = model.sheepGameQuestionsCounter + 1
                      }
                    , SaveSheepGameQuestions Array.empty :: outMsg2
                    )

        CheckedSheepGameAnswerDebounce matchId questionId counter ->
            case
                ( SeqDict.get ( matchId, questionId ) model.sheepGameAnswerCounters == Just counter
                , SeqDict.get matchId model.startedGames
                )
            of
                ( True, Just (SheepGame_Game game) ) ->
                    ( model
                    , [ SheepGame.saveAnswerAction localUser questionId game
                            |> (\action -> { userId = currentUserId, time = time, change = action })
                            |> SheepGame.Action
                            |> LocalChange_SheepGame matchId
                            |> OutLocalChange
                      ]
                    )

                _ ->
                    -- More typing happened after this save was asked for, so the one that
                    -- typing scheduled will cover it.
                    ( model, [] )

        CheckedSheepGameQuestionsDebounce counter ->
            case ( counter == model.sheepGameQuestionsCounter, model.setup ) of
                ( True, SheepGame_Setup setup ) ->
                    ( model, [ IdArray.toArray setup.questions |> SheepGame.clampSavedQuestions |> SaveSheepGameQuestions ] )

                _ ->
                    -- More typing happened after this save was asked for, so the one that
                    -- typing scheduled will cover it.
                    ( model, [] )

        PressedSelectGame game ->
            case game of
                GameType_Go ->
                    ( { model | setup = GoModel_Setup Go.initSetup }, [] )

                GameType_WordSpellingGame ->
                    ( { model | setup = WordSpellingGame_Setup WordSpellingGame.initSetup }, [] )

                GameType_SheepGame ->
                    ( { model
                        | setup =
                            SheepGame.initSetupFromSavedQuestions localUser.session.savedSheepGameQuestions
                                |> SheepGame_Setup
                      }
                    , []
                    )

        PressedReset ->
            ( { model | setup = GameSelect }, [ OutSelectMatch Nothing ] )

        SelectedMatch selectedMatchId ->
            ( model, [ OutSelectMatch (Just selectedMatchId) ] )

        NoOpMsg ->
            ( model, [] )


{-| What the sheep game asks of whatever is drawing it. The setup and the game both ask for
the same things about an input, so both go through here.
-}
sheepGameOutMsgs : Time.Posix -> Id ChannelMessageId -> SheepGame.OutMsg -> List OutMsg
sheepGameOutMsgs time newMatchId outMsg =
    case outMsg of
        SheepGame.FinishedSetup setup ->
            -- A brand new match takes the next message id, then we navigate to it.
            [ OutLocalChange (LocalChange_SheepGame newMatchId (SheepGame.StartMatch time setup))
            , OutSelectMatch (Just newMatchId)
            ]

        SheepGame.NoOutMsg ->
            []

        SheepGame.OpenEmojiSelector input ->
            [ OpenSheepGameEmojiSelector input ]

        SheepGame.SelectFilesToAttach input ->
            [ SelectSheepGameFilesToAttach input ]

        SheepGame.UploadAttachedFiles input files ->
            [ UploadSheepGameAttachedFiles input files ]

        SheepGame.CancelAttachedFileUpload input fileId ->
            [ CancelSheepGameAttachedFileUpload input fileId ]

        SheepGame.ShowAttachedFileInfo fileData ->
            [ ShowSheepGameAttachedFileInfo fileData ]


{-| Files someone picked for one of the sheep game's inputs, on their way back to whichever
of the setup and the game holds that input.
-}
sheepGameFilesToAttach : SheepGame.Input -> Nonempty File -> Msg
sheepGameFilesToAttach input files =
    case input of
        SheepGame.QuestionInput questionId ->
            SheepSetupMsg (SheepGame.GotFilesToAttach questionId files)

        SheepGame.AnswerInput questionId ->
            SheepGameMsg (SheepGame.GotAnswerFiles questionId files)


sheepGameFileUploaded :
    SheepGame.Input
    -> Id FileId
    -> Result Http.Error FileStatus.UploadResponse
    -> Msg
sheepGameFileUploaded input fileId result =
    case input of
        SheepGame.QuestionInput questionId ->
            SheepSetupMsg (SheepGame.GotAttachedFileUpload questionId fileId result)

        SheepGame.AnswerInput questionId ->
            SheepGameMsg (SheepGame.GotAnswerFileUpload questionId fileId result)


{-| How long the host has to stop typing for before their questions are sent to be saved.
-}
sheepGameQuestionsSaveDelay : Duration
sheepGameQuestionsSaveDelay =
    Duration.seconds 1


{-| How long a player has to stop typing an answer for before it's sent to be saved.
-}
sheepGameAnswerSaveDelay : Duration
sheepGameAnswerSaveDelay =
    Duration.seconds 1


dragStart :
    Time.Posix
    -> Coord CssPixels
    -> Id UserId
    -> NonemptyDict Int Touch
    -> Id ChannelMessageId
    -> MatchData
    -> Model
    -> Model
dragStart time windowSize currentUserId touches matchId matchData model =
    case matchData of
        MatchData matchData2 ->
            { model
                | startedGames =
                    SeqDict.updateIfExists
                        matchId
                        (\game ->
                            case matchData2.data of
                                FrontendGameData_Go _ _ _ ->
                                    case game of
                                        GoModel_Game game2 ->
                                            Go.dragStart game2 |> GoModel_Game

                                        _ ->
                                            game

                                FrontendGameData_WordSpellingGame setup _ shared ->
                                    case game of
                                        WordSpellingGame_Game game2 ->
                                            WordSpellingGame.dragStart time windowSize currentUserId touches setup shared game2
                                                |> WordSpellingGame_Game

                                        _ ->
                                            game

                                FrontendGameData_SheepGame _ _ _ ->
                                    game
                        )
                        model.startedGames
            }

        MatchNotLoaded _ ->
            model


dragEnd :
    Time.Posix
    -> Coord CssPixels
    -> Id UserId
    -> NonemptyDict Int Touch
    -> Id ChannelMessageId
    -> MatchData
    -> Model
    -> ( Model, Maybe LocalChange )
dragEnd time windowSize currentUserId touches matchId matchData model =
    case ( matchData, SeqDict.get matchId model.startedGames ) of
        ( MatchData matchData2, Just game ) ->
            let
                ( game4, outMsg ) =
                    case matchData2.data of
                        FrontendGameData_Go _ _ _ ->
                            ( case game of
                                GoModel_Game game2 ->
                                    Go.dragEnd game2 |> GoModel_Game

                                _ ->
                                    game
                            , Nothing
                            )

                        FrontendGameData_WordSpellingGame setup _ shared ->
                            case game of
                                WordSpellingGame_Game game2 ->
                                    let
                                        ( game3, shouldEndPremove ) =
                                            WordSpellingGame.dragEnd
                                                time
                                                windowSize
                                                currentUserId
                                                touches
                                                setup
                                                shared
                                                game2
                                    in
                                    ( WordSpellingGame_Game game3
                                    , if shouldEndPremove then
                                        { userId = currentUserId, time = time, change = WordSpellingGame.CancelPremove }
                                            |> WordSpellingGame.Action
                                            |> LocalChange_WordSpellingGame matchId
                                            |> Just

                                      else
                                        Nothing
                                    )

                                _ ->
                                    ( game, Nothing )

                        FrontendGameData_SheepGame _ _ _ ->
                            ( game, Nothing )
            in
            ( { model | startedGames = SeqDict.insert matchId game4 model.startedGames }, outMsg )

        ( MatchNotLoaded _, Just _ ) ->
            ( model, Nothing )

        ( _, Nothing ) ->
            ( model, Nothing )


view :
    Time.Posix
    -> Coord CssPixels
    -> Bool
    -> Maybe (NonemptyDict Int Touch)
    -> Maybe MyUi.LastCopy
    -> LocalUser
    -> SheepGame.LoggedIn a
    -> GuildOrDmId
    -> Maybe (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Model
    -> Element Msg
view currentTime windowSize showMemberTab maybeDragging lastCopied localUser loggedIn guildOrDmId maybeMatchId matches model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize

        isPersonalDm : Bool
        isPersonalDm =
            guildOrDmId == GuildOrDmId_Dm { otherUserId = localUser.session.userId }
    in
    case maybeMatchId of
        Just matchId ->
            case ( SeqDict.get matchId matches, SeqDict.get matchId model.startedGames ) of
                ( Just (MatchNotLoaded _), _ ) ->
                    Ui.el
                        [ Ui.centerX, Ui.centerY, Ui.Font.bold, Ui.Font.size 20 ]
                        (Ui.text "Loading match")

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
                                        showMemberTab
                                        maybeDragging
                                        isPersonalDm
                                        localUser
                                        setup
                                        actions
                                        cache
                                        game2
                                        |> Ui.map WordSpellingGameMsg

                                _ ->
                                    matchNotFound

                        FrontendGameData_SheepGame setup _ cache ->
                            case game of
                                SheepGame_Game game2 ->
                                    SheepGame.gameView currentTime windowSize showMemberTab localUser loggedIn setup cache game2
                                        |> Ui.map SheepGameMsg

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
                        Go.setupView isPersonalDm windowSize setup |> Ui.map GoSetupMsg

                    WordSpellingGame_Setup setup ->
                        WordSpellingGame.setupView windowSize False setup |> Ui.map WordSpellingSetupMsg

                    SheepGame_Setup setup ->
                        SheepGame.setupView windowSize localUser loggedIn (User.allUsers localUser) setup
                            |> Ui.map SheepSetupMsg

                    GameSelect ->
                        Ui.row
                            [ Ui.spacing 8
                            , Ui.wrap
                            , Ui.padding 8
                            , if isMobile then
                                Ui.centerX

                              else
                                Ui.alignLeft
                            ]
                            (List.map (gameSelectButton isMobile) allGames)
                ]


allGames : List GameType
allGames =
    [ GameType_Go
    , GameType_WordSpellingGame
    , GameType_SheepGame
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


gameToString : GameType -> String
gameToString game =
    case game of
        GameType_Go ->
            goName

        GameType_WordSpellingGame ->
            wordSpellingGameName

        GameType_SheepGame ->
            sheepGameName


goName =
    "Go (Baduk)"


wordSpellingGameName =
    "Word Spelling Game"


sheepGameName =
    "Sheep Game (WIP)"


gameToPreviewUrl : GameType -> String
gameToPreviewUrl game =
    case game of
        GameType_Go ->
            "/go-preview.webp"

        GameType_WordSpellingGame ->
            "/word-spelling-game-preview.webp"

        GameType_SheepGame ->
            "/sheep-game-preview.jpg"


gameSelectButton : Bool -> GameType -> Element Msg
gameSelectButton isMobile game =
    MyUi.elButton
        (Dom.id ("game_select_" ++ gameToString game))
        (PressedSelectGame game)
        [ Ui.width
            (Ui.px
                (if isMobile then
                    170

                 else
                    240
                )
            )
        , Ui.height
            (Ui.px
                (if isMobile then
                    170

                 else
                    240
                )
            )
        , Ui.rounded 16
        , Ui.clip
        , Ui.contentCenterY
        , Ui.Font.size
            (if isMobile then
                16

             else
                18
            )
        , Ui.Font.center
        , Ui.Font.bold
        , gameToString game
            |> Ui.text
            |> Ui.el
                [ Ui.contentCenterX
                , Ui.contentCenterY
                , Ui.alignBottom
                , Ui.background (Ui.rgba 0 0 0 0.7)
                , Ui.Shadow.shadows [ { x = 0, y = 0, size = 0, blur = 100, color = Ui.rgba 0 0 0 1 } ]
                , Ui.heightMin
                    (if isMobile then
                        32

                     else
                        40
                    )
                ]
            |> Ui.inFront
        ]
        (Ui.imageLazy [] { source = gameToPreviewUrl game, description = "", onLoad = Nothing })


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
        Ui.el
            [ Ui.padding
                8
            ]
            (Ui.html
                (Html.select
                    [ Html.Attributes.id "game_matchSwitcher"
                    , Html.Attributes.value currentValue
                    , Html.Events.onInput onSelect
                    , Html.Attributes.style "width" "fit-content"
                    , Html.Attributes.attribute "aria-label" "View match"
                    , Html.Attributes.style "padding"
                        (if isMobile then
                            "4px"

                         else
                            "7px 8px"
                        )
                    , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
                    , Html.Attributes.style "border-radius" "4px"
                    , Html.Attributes.style "font-size"
                        (if isMobile then
                            "14px"

                         else
                            "16px"
                        )
                    , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background2)
                    , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.white)
                    , Html.Attributes.style "cursor" "pointer"
                    ]
                    (Html.option
                        [ Html.Attributes.value newMatchValue
                        , Html.Attributes.selected (maybeMatchId == Nothing)
                        ]
                        [ Html.text "View existing match" ]
                        :: List.map
                            (\( matchId, matchData ) ->
                                let
                                    matchIdText : String
                                    matchIdText =
                                        Id.toString matchId

                                    text : String
                                    text =
                                        case matchData of
                                            MatchData matchData2 ->
                                                case matchData2.data of
                                                    FrontendGameData_Go _ _ _ ->
                                                        goName

                                                    FrontendGameData_WordSpellingGame _ _ _ ->
                                                        wordSpellingGameName

                                                    FrontendGameData_SheepGame _ _ _ ->
                                                        sheepGameName

                                            MatchNotLoaded gameType ->
                                                gameToString gameType
                                in
                                Html.option
                                    [ Html.Attributes.value matchIdText
                                    , Html.Attributes.selected (Just matchId == maybeMatchId)
                                    ]
                                    [ Html.text ("#" ++ matchIdText ++ " " ++ text) ]
                            )
                            (SeqDict.toList matches)
                    )
                )
            )


pressedKey : Id ChannelMessageId -> String -> MatchData -> Maybe Model -> Maybe Model
pressedKey matchId key matchData maybeGameModel =
    case matchData of
        MatchData matchData2 ->
            let
                model : Model
                model =
                    Maybe.withDefault initModel maybeGameModel
            in
            { model
                | startedGames =
                    SeqDict.updateIfExists
                        matchId
                        (\game ->
                            case matchData2.data of
                                FrontendGameData_Go _ _ shared ->
                                    case game of
                                        GoModel_Game game2 ->
                                            Go.pressedKey key shared game2
                                                |> GoModel_Game

                                        _ ->
                                            game

                                FrontendGameData_WordSpellingGame _ _ _ ->
                                    case game of
                                        WordSpellingGame_Game game2 ->
                                            WordSpellingGame.pressedKey game2
                                                |> WordSpellingGame_Game

                                        _ ->
                                            game

                                FrontendGameData_SheepGame _ _ _ ->
                                    game
                        )
                        model.startedGames
            }
                |> Just

        MatchNotLoaded _ ->
            Nothing


gameChangeFromServer : Time.Posix -> LocalUser -> LocalChange -> Maybe Model -> Maybe Model
gameChangeFromServer time localUser gameChange maybeModel =
    let
        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId

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

                                Go.Joined _ ->
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

        LoadMatch _ _ ->
            model

        LocalChange_WordSpellingGame matchId wordSpellinGameChange ->
            case wordSpellinGameChange of
                WordSpellingGame.StartMatch serverTime setup ->
                    { model
                        | startedGames =
                            SeqDict.insert
                                matchId
                                (WordSpellingGame_Game
                                    (WordSpellingGame.initGame
                                        serverTime
                                        currentUserId
                                        setup
                                        (WordSpellingGame.initShared setup)
                                    )
                                )
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

        LocalChange_SheepGame matchId sheepChange ->
            case sheepChange of
                SheepGame.StartMatch _ setup ->
                    { model
                        | startedGames =
                            SeqDict.insert
                                matchId
                                (SheepGame_Game (SheepGame.initGame localUser setup SheepGame.initShared))
                                model.startedGames
                    }

                SheepGame.Action _ ->
                    model
    )
        |> Just
