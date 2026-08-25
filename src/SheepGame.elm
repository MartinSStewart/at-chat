module SheepGame exposing
    ( Action(..)
    , ActionWithTime
    , AnswerResult
    , GameData
    , GameMsg(..)
    , Input(..)
    , LocalChange(..)
    , LoggedIn
    , OutMsg(..)
    , Phase(..)
    , QuestionResult
    , RankChange(..)
    , ReactionTarget(..)
    , Reactions
    , SetupModel
    , SetupMsg(..)
    , SetupOrGame(..)
    , Shared
    , UnvalidatedInput
    , ValidatedInput
    , ValidatedSetup
    , attachedFileTrackerId
    , changedInputs
    , clampSavedQuestions
    , fileUploadPreview
    , fileUploadPreviewSize
    , gameView
    , gameViewId
    , initGame
    , initSetup
    , initSetupFromSavedQuestions
    , initShared
    , inputContainerId
    , inputId
    , mapQuestionRichText
    , questionRevealed
    , reactionTargetId
    , removeAttachedFileFromText
    , resultsData
    , revealedQuestionId
    , saveInputAction
    , scoresThroughQuestion
    , scoringId
    , setupView
    , updateAction
    , updateGame
    , updateSetup
    , validateSetup
    )

{-| The Sheep Game: everyone answers the same questions and you score points for every
player who wrote the same answer as you, so the goal is to be as unoriginal as possible.

The host writes the questions while setting the game up, everyone answers them, then the
host groups the answers that count as the same thing (people phrase things differently)
before revealing the questions one at a time.

-}

import Array
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.File exposing (File)
import Effect.Http as Http
import Effect.Time as Time
import Emoji exposing (EmojiOrCustomEmoji)
import FileName
import FileStatus exposing (FileData, FileId, FileMetadata(..), FileStatus)
import Go
import GuildIcon
import Html
import Html.Attributes
import Icons
import Id exposing (Id, QuestionId, UserId)
import IdArray exposing (IdArray)
import List.Extra
import List.Nonempty exposing (Nonempty)
import MessageInput exposing (TextInputFocus)
import MessageView
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import RichText exposing (RichText)
import Scroll exposing (ScrollPosition(..))
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet
import Sticker
import String.Nonempty
import Touch exposing (Drag(..), Touch)
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Lazy
import Ui.Prose
import Ui.Shadow
import User exposing (FrontendUser, LocalUser)
import UserColor


type alias ValidatedSetup =
    { questions : Nonempty ValidatedInput
    , createdBy : Id UserId
    }


type alias LoggedIn a =
    { a | typedTextCounter : Int, textInputFocus : Maybe TextInputFocus }


{-| Which stage the match has reached. The host drives every transition.
-}
type Phase
    = Answering
    | Grouping
    | Revealing


{-| Answers people wrote, and how the host decided to group them.

`groups` gives each answer a label, and answers sharing a label for a question count as
the same answer when scoring. It's filled in automatically when the host locks the
answers and then corrected by hand, because "a dog" and "dogs" should score together but
no amount of string comparison is going to work that out.

-}
type alias Shared =
    { phase : Phase
    , answers : SeqDict (Id UserId) (IdArray QuestionId (Maybe ValidatedInput))
    , groups : SeqDict ( Id UserId, Id QuestionId ) String
    , notes : SeqDict (Id QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type alias UnvalidatedInput =
    { text : String, attachedFiles : SeqDict (Id FileId) FileStatus }


type alias ValidatedInput =
    { text : Nonempty (RichText (Id UserId))
    , attachedFiles : SeqDict (Id FileId) FileData
    , reactions : Reactions
    }


type alias Reactions =
    SeqDict EmojiOrCustomEmoji (NonemptySet (Id UserId))


{-| Something on the results screen that can be reacted to: what one player answered to one
question, or what the host wrote about that question.
-}
type ReactionTarget
    = AnswerReaction (Id UserId) (Id QuestionId)
    | NotesReaction (Id QuestionId)


type alias SetupModel =
    { questions : IdArray QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }


type SetupMsg
    = TypedQuestion (Id QuestionId) MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Id QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Id QuestionId) (Nonempty File)
    | GotAttachedFileUpload (Id QuestionId) (Id FileId) (Result Http.Error FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Id QuestionId) (Id FileId)
    | PressedViewAttachedFileInfo (Id QuestionId) (Id FileId)
    | PressedToggleAttachedFileSpoiler (Id QuestionId) { fileId : Id FileId, removeSpoiler : Bool }


type SetupOrGame
    = Setup SetupModel
    | Game GameData
    | CancelSetup


{-| View state that belongs to one player and never reaches anyone else.
-}
type alias GameData =
    { -- What's in each answer box right now. Saving happens on a delay, so this is ahead
      -- of what everyone else has been told until the typing stops.
      answerDrafts : IdArray QuestionId UnvalidatedInput
    , -- What the host has written about each question so far, saved the same way an answer
      -- is.
      noteDrafts : IdArray QuestionId UnvalidatedInput
    , -- Which pair of players the cursor is over in the results grid, so their row and
      -- column light up and how much they matched is spelled out beside it.
      gridHovered : Maybe ( Id UserId, Id UserId )
    , -- How far the tab body is scrolled, which decides what happens when the host puts
      -- another question on screen.
      scrollPosition : ScrollPosition
    , -- How many questions were revealed the last time this client reacted to that count
      -- changing. The host can go back to an earlier question, and going forward again
      -- isn't a question nobody has seen yet.
      questionsRevealedSeen : Int
    , -- Whether a question turned up while the reader was somewhere further up the tab, in
      -- which case they're told about it instead of being scrolled onto it.
      newQuestionRevealed : Bool
    , -- Which answer or note the pointer is over, which is the one offering to be reacted to.
      hoveredResult : Maybe ReactionTarget
    }


type GameMsg
    = TypedAnswer (Id QuestionId) MessageInput.Msg
    | GotAnswerFiles (Id QuestionId) (Nonempty File)
    | GotAnswerFileUpload (Id QuestionId) (Id FileId) (Result Http.Error FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Id QuestionId) (Id FileId)
    | PressedViewAnswerFileInfo (Id QuestionId) (Id FileId)
    | PressedToggleAnswerFileSpoiler (Id QuestionId) { fileId : Id FileId, removeSpoiler : Bool }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Id UserId) (Id QuestionId) String
    | TypedNotes (Id QuestionId) MessageInput.Msg
    | GotNotesFiles (Id QuestionId) (Nonempty File)
    | GotNotesFileUpload (Id QuestionId) (Id FileId) (Result Http.Error FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Id QuestionId) (Id FileId)
    | PressedViewNotesFileInfo (Id QuestionId) (Id FileId)
    | PressedToggleNotesFileSpoiler (Id QuestionId) { fileId : Id FileId, removeSpoiler : Bool }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Id UserId, Id UserId )
    | ExitedResultsGrid ( Id UserId, Id UserId )
    | UserScrolledResults ScrollPosition
    | ReactionMsg ReactionTarget MessageView.MessageViewMsg
    | PressedImage RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type Action
    = SubmittedAnswer (Id QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Id UserId) (Id QuestionId) String
    | ChangedNotes (Id QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Id QuestionId)
    | AddedReaction ReactionTarget EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Id UserId, time : Time.Posix, change : Action }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


initSetup : SetupModel
initSetup =
    { questions =
        IdArray.fromList
            [ { text = "Pick a random number between 1 and 10", attachedFiles = SeqDict.empty }
            , { text = "What's your favorite color?", attachedFiles = SeqDict.empty }
            ]
    , error = Nothing
    , pressedSubmit = False
    }


{-| The setup someone was part way through, rebuilt from the questions their session held
onto so that a refresh doesn't cost them what they'd written.
-}
initSetupFromSavedQuestions : IdArray QuestionId UnvalidatedInput -> SetupModel
initSetupFromSavedQuestions questions =
    if IdArray.isEmpty questions then
        initSetup

    else
        { questions = questions, error = Nothing, pressedSubmit = False }


{-| File ids start at 1. The backend throws away anything lower when it checks that the
files a client named were really uploaded, so an empty dict can't start from `Id.nextId`.
-}
nextAttachedFileId : SeqDict (Id FileId) a -> Id FileId
nextAttachedFileId attachedFiles =
    Id.nextId attachedFiles |> Id.toInt |> max 1 |> Id.fromInt


{-| Attaching a file adds a reference to it at the end of the question, the same text a
message's draft gets when a file is attached to it.
-}
appendAttachedFiles : List (Id FileId) -> String -> String
appendAttachedFiles fileIds question =
    List.foldl
        (\fileId text ->
            text ++ RichText.attachedFilePrefix ++ Id.toString fileId ++ RichText.attachedFileSuffix
        )
        (if question == "" || String.endsWith " " question then
            question

         else
            question ++ " "
        )
        fileIds


{-| How much of what a session asks to save is worth keeping. Nothing stops a client from
sending more than the setup view lets anyone write, and this ends up in the backend's
state, so it gets the same limits here.
-}
clampSavedQuestions : IdArray QuestionId UnvalidatedInput -> IdArray QuestionId UnvalidatedInput
clampSavedQuestions questions =
    IdArray.slice (Id.fromInt 0) (Id.fromInt maxQuestions) questions
        |> IdArray.map (\_ question -> { question | text = String.left maxQuestionLength question.text })


{-| Someone opening a match they've already answered gets their own answers back in the
boxes rather than a screen full of blanks. They come back as the text that was typed to
produce them, which is what the boxes take.
-}
initGame : LocalUser -> ValidatedSetup -> Shared -> GameData
initGame localUser setup shared =
    { answerDrafts =
        (case SeqDict.get localUser.session.userId shared.answers of
            Just answers ->
                IdArray.toList answers |> List.map (toDraft localUser)

            Nothing ->
                List.repeat (List.Nonempty.length setup.questions) emptyInput
        )
            |> IdArray.fromList
    , noteDrafts =
        List.range 0 (List.Nonempty.length setup.questions - 1)
            |> List.map
                (\index -> SeqDict.get (Id.fromInt index) shared.notes |> Maybe.withDefault Nothing |> toDraft localUser)
            |> IdArray.fromList
    , gridHovered = Nothing
    , scrollPosition = ScrolledToBottom
    , questionsRevealedSeen = shared.questionsRevealed
    , newQuestionRevealed = False
    , hoveredResult = Nothing
    }


{-| Something already saved, back as the text that was typed to produce it, which is what
the box it came from takes.
-}
toDraft : LocalUser -> Maybe ValidatedInput -> UnvalidatedInput
toDraft localUser saved =
    case saved of
        Just saved2 ->
            { text = toSourceText localUser saved2.text
            , attachedFiles = SeqDict.map (\_ fileData -> FileStatus.FileUploaded fileData) saved2.attachedFiles
            }

        Nothing ->
            emptyInput


{-| The text someone would have typed to write this, so that an answer can be put back in
the box it came from.
-}
toSourceText : LocalUser -> Nonempty (RichText (Id UserId)) -> String
toSourceText localUser content =
    RichText.toString localUser.timezone False (User.allUsers localUser) content


initShared : Shared
initShared =
    { phase = Answering
    , answers = SeqDict.empty
    , groups = SeqDict.empty
    , notes = SeqDict.empty
    , questionsRevealed = 0
    }


emptyInput : UnvalidatedInput
emptyInput =
    { text = "", attachedFiles = SeqDict.empty }


maxQuestions : Int
maxQuestions =
    50


maxQuestionLength : Int
maxQuestionLength =
    200


maxAnswerLength : Int
maxAnswerLength =
    200


maxNoteLength : Int
maxNoteLength =
    400


{-| A question or an answer, ready to go to everyone else, or why it isn't. Blank text is
how an answer says the player hasn't written one yet, so the setup is the only place that
shows these.
-}
validateInput : Time.Zone -> SeqDict (Id UserId) FrontendUser -> UnvalidatedInput -> Result String (() -> ValidatedInput)
validateInput timezone users question =
    case
        ( String.trim question.text |> String.Nonempty.fromString
        , FileStatus.hasUploadingFile question.attachedFiles
        )
    of
        ( Just content, False ) ->
            -- Lazy so we can show error messages without having to parse everything
            (\() ->
                { text = RichText.fromNonemptyString timezone users content
                , attachedFiles = FileStatus.onlyUploadedFiles question.attachedFiles
                , reactions = SeqDict.empty
                }
            )
                |> Ok

        ( Nothing, _ ) ->
            Err "Can't be empty"

        ( _, True ) ->
            Err "Attached files not finished uploading"


{-| The host's questions, or a reason they can't be used yet.
-}
validateSetup : Time.Zone -> SeqDict (Id UserId) FrontendUser -> Id UserId -> SetupModel -> Result String ValidatedSetup
validateSetup timezone users createdBy model =
    case
        IdArray.toList model.questions
            |> List.filterMap (\question -> validateInput timezone users question |> Result.toMaybe)
            |> List.Nonempty.fromList
    of
        Just questions ->
            if IdArray.length model.questions == List.Nonempty.length questions then
                Ok { questions = List.Nonempty.map (\a -> a ()) questions, createdBy = createdBy }

            else
                Err ""

        Nothing ->
            Err "Write at least one question before starting"


{-| What the setup and the game can't do for themselves. Everything about an input works
the same whether it holds a question or an answer, so these say which input rather than
which of the two it is.
-}
type OutMsg
    = NoOutMsg
    | FinishedSetup ValidatedSetup
    | OpenEmojiSelector Input
    | SelectFilesToAttach Input
    | UploadAttachedFiles Input (Nonempty ( Id FileId, File ))
    | CancelAttachedFileUpload Input (Id FileId)
    | ShowAttachedFileInfo FileStatus.FileDataWithImage
      -- Take the reader to the question they were told about, the same way they'd have been
      -- taken there had they been at the bottom of the tab body when it turned up.
    | ScrollResultsTo HtmlId
      -- Somebody wants to react with an emoji that isn't one of the ones they reach for
      -- most, so the full selector has to be opened for them.
    | OpenReactionEmojiSelector ReactionTarget
      -- An image attached to a question, an answer or a note, pressed to see it full size.
      -- Where that gets shown is the frontend's business rather than the game's.
    | ShowImage RichText.PressedImageData
    | SetFocusOnQuestion (Id QuestionId)


updateSetup : LocalUser -> SetupMsg -> SetupModel -> ( SetupOrGame, OutMsg )
updateSetup localUser msg model =
    case msg of
        TypedQuestion questionId messageInputMsg ->
            case messageInputMsg of
                MessageInput.PressedTextInput ->
                    -- Clicking the input is how the rich text drawn in front of it gets edited, but
                    -- the focus itself is handled by the port that watches the text selection.
                    ( Setup model, NoOutMsg )

                MessageInput.TypedMessage text ->
                    ( Setup
                        { model
                            | questions =
                                IdArray.update questionId (\question -> { question | text = text }) model.questions
                            , error = Nothing
                        }
                    , NoOutMsg
                    )

                MessageInput.PressedSendMessage { charsLeft } ->
                    if charsLeft == maxQuestionLength then
                        ( Setup model, NoOutMsg )

                    else
                        ( { model
                            | questions =
                                IdArray.append
                                    (IdArray.slice (Id.fromInt 0) (Id.increment questionId) model.questions
                                        |> IdArray.push { text = "", attachedFiles = SeqDict.empty }
                                    )
                                    (IdArray.slice (Id.increment questionId) (IdArray.nextId model.questions) model.questions)
                          }
                            |> Setup
                        , SetFocusOnQuestion (Id.increment questionId)
                        )

                -- The mention and emoji dropdown never opens over a question. The frontend
                -- only fills in `textInputFocus.dropdown` for the channel and edit message
                -- inputs, and these three are the ones that need it to be open.
                MessageInput.TypedArrowInDropdown _ ->
                    ( Setup model, NoOutMsg )

                -- Pressing up in an empty channel input starts editing the last message you
                -- wrote. A question has nothing of the sort behind it.
                MessageInput.TypedArrowUpInEmptyInput ->
                    ( Setup model, NoOutMsg )

                MessageInput.PressedDropdownItem _ ->
                    ( Setup model, NoOutMsg )

                MessageInput.PressedPingDropdownContainer ->
                    ( Setup model, NoOutMsg )

                MessageInput.PressedUploadFile ->
                    ( Setup model, SelectFilesToAttach (QuestionInput questionId) )

                MessageInput.PressedOpenEmojiSelector ->
                    ( Setup model, OpenEmojiSelector (QuestionInput questionId) )

                MessageInput.OnPasteFiles files ->
                    attachQuestionFiles questionId files model

                MessageInput.TypedPageUp ->
                    ( Setup model, NoOutMsg )

                MessageInput.TypedPageDown ->
                    ( Setup model, NoOutMsg )

                MessageInput.TypedTabInCodeBlock _ ->
                    ( Setup model, NoOutMsg )

                MessageInput.IgnoredKeyPress ->
                    ( Setup model, NoOutMsg )

        PressedAddQuestion ->
            ( Setup
                { model
                    | questions =
                        if IdArray.length model.questions >= maxQuestions then
                            model.questions

                        else
                            IdArray.push { text = "", attachedFiles = SeqDict.empty } model.questions
                    , error = Nothing
                }
            , SetFocusOnQuestion (IdArray.nextId model.questions)
            )

        PressedRemoveQuestion index ->
            ( Setup
                { model
                    | questions =
                        IdArray.toList model.questions
                            |> List.Extra.removeAt (Id.toInt index)
                            |> IdArray.fromList
                    , error = Nothing
                }
            , NoOutMsg
            )

        PressedStartGame ->
            case validateSetup localUser.timezone (User.allUsers localUser) localUser.session.userId model of
                Ok setup ->
                    ( Game (initGame localUser setup initShared), FinishedSetup setup )

                Err error ->
                    ( Setup { model | error = Just error, pressedSubmit = True }, NoOutMsg )

        GotFilesToAttach questionId files ->
            attachQuestionFiles questionId files model

        GotAttachedFileUpload questionId fileId result ->
            ( Setup
                { model
                    | questions =
                        IdArray.update
                            questionId
                            (\question ->
                                { question
                                    | attachedFiles =
                                        SeqDict.updateIfExists fileId (FileStatus.addFileHash result) question.attachedFiles
                                }
                            )
                            model.questions
                }
            , NoOutMsg
            )

        PressedCancel ->
            ( CancelSetup, NoOutMsg )

        PressedDeleteAttachedFile questionId fileId ->
            ( Setup
                { model
                    | questions =
                        IdArray.update
                            questionId
                            (\question ->
                                { question
                                    | attachedFiles = SeqDict.remove fileId question.attachedFiles
                                    , text =
                                        removeAttachedFileFromText
                                            localUser.timezone
                                            (User.allUsers localUser)
                                            fileId
                                            question.text
                                }
                            )
                            model.questions
                    , error = Nothing
                }
            , CancelAttachedFileUpload (QuestionInput questionId) fileId
            )

        PressedViewAttachedFileInfo questionId fileId ->
            ( Setup model
            , case attachedFile questionId fileId model of
                Just (FileStatus.FileUploaded fileData) ->
                    case fileData.metadata of
                        Just metadata ->
                            ShowAttachedFileInfo
                                { fileName = fileData.fileName
                                , fileSize = fileData.fileSize
                                , metadata = metadata
                                , contentType = fileData.contentType
                                , fileHash = fileData.fileHash
                                }

                        -- The button that sends this is only drawn for a file that has
                        -- something to show, so there's nothing to do here.
                        Nothing ->
                            NoOutMsg

                _ ->
                    NoOutMsg
            )

        PressedToggleAttachedFileSpoiler questionId { fileId, removeSpoiler } ->
            ( Setup
                { model
                    | questions =
                        IdArray.update
                            questionId
                            (\question ->
                                { question
                                    | text =
                                        mapQuestionRichText
                                            localUser.timezone
                                            (User.allUsers localUser)
                                            (if removeSpoiler then
                                                RichText.unspoilerAttachedFile fileId

                                             else
                                                RichText.spoilerAttachedFile fileId
                                            )
                                            question.text
                                }
                            )
                            model.questions
                    , error = Nothing
                }
            , NoOutMsg
            )


{-| Files someone picked or pasted, added to the input they were meant for. Each one gets a
reference at the end of that input's text, the same text a message's draft gets when a file
is attached to it.
-}
attachFiles :
    Input
    -> Nonempty File
    -> IdArray QuestionId UnvalidatedInput
    -> ( IdArray QuestionId UnvalidatedInput, OutMsg )
attachFiles input files inputs =
    let
        questionId : Id QuestionId
        questionId =
            inputQuestionId input

        ( attachedFiles, toUpload ) =
            List.Nonempty.foldl
                (\file ( attachedFiles2, toUpload2 ) ->
                    let
                        fileId : Id FileId
                        fileId =
                            nextAttachedFileId attachedFiles2
                    in
                    ( SeqDict.insert
                        fileId
                        (FileStatus.FileUploading
                            (Effect.File.name file |> FileName.fromString)
                            { sent = 0, size = Effect.File.size file }
                            (Effect.File.mime file |> FileStatus.contentType)
                        )
                        attachedFiles2
                    , ( fileId, file ) :: toUpload2
                    )
                )
                (case IdArray.get questionId inputs of
                    Just input2 ->
                        ( input2.attachedFiles, [] )

                    Nothing ->
                        ( SeqDict.empty, [] )
                )
                files

        added : List ( Id FileId, File )
        added =
            List.reverse toUpload
    in
    ( IdArray.update
        questionId
        (\input2 ->
            { input2
                | attachedFiles = attachedFiles
                , text = appendAttachedFiles (List.map Tuple.first added) input2.text
            }
        )
        inputs
    , case List.Nonempty.fromList added of
        Just nonempty ->
            UploadAttachedFiles input nonempty

        Nothing ->
            NoOutMsg
    )


inputQuestionId : Input -> Id QuestionId
inputQuestionId input =
    case input of
        QuestionInput questionId ->
            questionId

        AnswerInput questionId ->
            questionId

        NotesInput questionId ->
            questionId


attachAnswerFiles : Id QuestionId -> Nonempty File -> GameData -> ( GameData, Maybe Action, OutMsg )
attachAnswerFiles questionId files model =
    let
        ( answerDrafts, outMsg ) =
            attachFiles (AnswerInput questionId) files model.answerDrafts
    in
    ( { model | answerDrafts = answerDrafts }, Nothing, outMsg )


attachNotesFiles : Id QuestionId -> Nonempty File -> GameData -> ( GameData, Maybe Action, OutMsg )
attachNotesFiles questionId files model =
    let
        ( noteDrafts, outMsg ) =
            attachFiles (NotesInput questionId) files model.noteDrafts
    in
    ( { model | noteDrafts = noteDrafts }, Nothing, outMsg )


attachQuestionFiles : Id QuestionId -> Nonempty File -> SetupModel -> ( SetupOrGame, OutMsg )
attachQuestionFiles questionId files model =
    let
        ( questions, outMsg ) =
            attachFiles (QuestionInput questionId) files model.questions
    in
    ( Setup { model | questions = questions, error = Nothing }, outMsg )


attachedFile : Id QuestionId -> Id FileId -> SetupModel -> Maybe FileStatus
attachedFile questionId fileId model =
    IdArray.get questionId model.questions
        |> Maybe.andThen (\question -> SeqDict.get fileId question.attachedFiles)


{-| File ids start again at 1 for every input, so an upload only tells itself apart from
another input's by carrying that input in its tracker id too.
-}
attachedFileTrackerId : Input -> Id FileId -> String
attachedFileTrackerId input fileId =
    "sheepGameAttachedFile-" ++ Dom.idToString (inputId input) ++ "-" ++ Id.toString fileId


{-| Rewrite a question by way of the rich text it produces and back into the text the input
holds. Text that isn't rich text yet has nothing in it to change.
-}
mapQuestionRichText :
    Time.Zone
    -> SeqDict (Id UserId) FrontendUser
    -> (Nonempty (RichText (Id UserId)) -> Nonempty (RichText (Id UserId)))
    -> String
    -> String
mapQuestionRichText timezone users change text =
    case String.Nonempty.fromString text of
        Just nonempty ->
            RichText.fromNonemptyString timezone users nonempty
                |> change
                |> RichText.toString timezone False users

        Nothing ->
            text


{-| What a question is left with once one of its files is gone, so that it doesn't go on
referring to a file nothing can resolve.
-}
removeAttachedFileFromText : Time.Zone -> SeqDict (Id UserId) FrontendUser -> Id FileId -> String -> String
removeAttachedFileFromText timezone users fileId text =
    case String.Nonempty.fromString text of
        Just nonempty ->
            case
                RichText.fromNonemptyString timezone users nonempty
                    |> RichText.removeAttachedFile (\a -> a == fileId)
            of
                Just richText ->
                    RichText.toString timezone False users richText

                -- The file was all the question had in it.
                Nothing ->
                    ""

        Nothing ->
            text


updateGame :
    LocalUser
    -> ValidatedSetup
    -> Shared
    -> GameMsg
    -> GameData
    -> ( GameData, Maybe Action, OutMsg )
updateGame localUser setup shared msg model =
    case msg of
        TypedAnswer questionId messageInputMsg ->
            case messageInputMsg of
                MessageInput.TypedMessage text ->
                    ( { model
                        | answerDrafts =
                            IdArray.update
                                questionId
                                (\draft -> { draft | text = String.left maxAnswerLength text })
                                model.answerDrafts
                      }
                    , Nothing
                    , NoOutMsg
                    )

                MessageInput.PressedUploadFile ->
                    ( model, Nothing, SelectFilesToAttach (AnswerInput questionId) )

                MessageInput.PressedOpenEmojiSelector ->
                    ( model, Nothing, OpenEmojiSelector (AnswerInput questionId) )

                MessageInput.OnPasteFiles files ->
                    attachAnswerFiles questionId files model

                -- The mention and emoji dropdown never opens over an answer, the frontend only
                -- fills it in for the channel and edit message inputs, and there's no last
                -- message behind an answer to start editing.
                _ ->
                    ( model, Nothing, NoOutMsg )

        GotAnswerFiles questionId files ->
            attachAnswerFiles questionId files model

        GotAnswerFileUpload questionId fileId result ->
            ( { model
                | answerDrafts =
                    IdArray.update
                        questionId
                        (\draft ->
                            { draft
                                | attachedFiles =
                                    SeqDict.updateIfExists fileId (FileStatus.addFileHash result) draft.attachedFiles
                            }
                        )
                        model.answerDrafts
              }
            , Nothing
            , NoOutMsg
            )

        PressedDeleteAnswerFile questionId fileId ->
            ( { model
                | answerDrafts =
                    IdArray.update
                        questionId
                        (\draft ->
                            { draft
                                | attachedFiles = SeqDict.remove fileId draft.attachedFiles
                                , text =
                                    removeAttachedFileFromText
                                        localUser.timezone
                                        (User.allUsers localUser)
                                        fileId
                                        draft.text
                            }
                        )
                        model.answerDrafts
              }
            , Nothing
            , CancelAttachedFileUpload (AnswerInput questionId) fileId
            )

        PressedViewAnswerFileInfo questionId fileId ->
            ( model
            , Nothing
            , case
                IdArray.get questionId model.answerDrafts
                    |> Maybe.andThen (\draft -> SeqDict.get fileId draft.attachedFiles)
              of
                Just (FileStatus.FileUploaded fileData) ->
                    case fileData.metadata of
                        Just metadata ->
                            ShowAttachedFileInfo
                                { fileName = fileData.fileName
                                , fileSize = fileData.fileSize
                                , metadata = metadata
                                , contentType = fileData.contentType
                                , fileHash = fileData.fileHash
                                }

                        Nothing ->
                            NoOutMsg

                _ ->
                    NoOutMsg
            )

        PressedToggleAnswerFileSpoiler questionId { fileId, removeSpoiler } ->
            ( { model
                | answerDrafts =
                    IdArray.update
                        questionId
                        (\draft ->
                            { draft
                                | text =
                                    mapQuestionRichText
                                        localUser.timezone
                                        (User.allUsers localUser)
                                        (if removeSpoiler then
                                            RichText.unspoilerAttachedFile fileId

                                         else
                                            RichText.spoilerAttachedFile fileId
                                        )
                                        draft.text
                            }
                        )
                        model.answerDrafts
              }
            , Nothing
            , NoOutMsg
            )

        PressedLockAnswers ->
            ( model, Just LockedAnswers, NoOutMsg )

        PressedUnlockAnswers ->
            ( model, Just UnlockedAnswers, NoOutMsg )

        TypedGroup userId questionIndex group ->
            ( model, Just (ChangedGroup userId questionIndex (String.left 1 group)), NoOutMsg )

        TypedNotes questionId messageInputMsg ->
            case messageInputMsg of
                MessageInput.TypedMessage text ->
                    ( { model
                        | noteDrafts =
                            IdArray.update
                                questionId
                                (\draft -> { draft | text = String.left maxAnswerLength text })
                                model.noteDrafts
                      }
                    , Nothing
                    , NoOutMsg
                    )

                MessageInput.PressedUploadFile ->
                    ( model, Nothing, SelectFilesToAttach (NotesInput questionId) )

                MessageInput.PressedOpenEmojiSelector ->
                    ( model, Nothing, OpenEmojiSelector (NotesInput questionId) )

                MessageInput.OnPasteFiles files ->
                    attachNotesFiles questionId files model

                -- The mention and emoji dropdown never opens over a note, the frontend only
                -- fills it in for the channel and edit message inputs, and there's no last
                -- message behind a note to start editing.
                _ ->
                    ( model, Nothing, NoOutMsg )

        GotNotesFiles questionId files ->
            attachNotesFiles questionId files model

        GotNotesFileUpload questionId fileId result ->
            ( { model
                | noteDrafts =
                    IdArray.update
                        questionId
                        (\draft ->
                            { draft
                                | attachedFiles =
                                    SeqDict.updateIfExists fileId (FileStatus.addFileHash result) draft.attachedFiles
                            }
                        )
                        model.noteDrafts
              }
            , Nothing
            , NoOutMsg
            )

        PressedDeleteNotesFile questionId fileId ->
            ( { model
                | noteDrafts =
                    IdArray.update
                        questionId
                        (\draft ->
                            { draft
                                | attachedFiles = SeqDict.remove fileId draft.attachedFiles
                                , text =
                                    removeAttachedFileFromText
                                        localUser.timezone
                                        (User.allUsers localUser)
                                        fileId
                                        draft.text
                            }
                        )
                        model.noteDrafts
              }
            , Nothing
            , CancelAttachedFileUpload (NotesInput questionId) fileId
            )

        PressedViewNotesFileInfo questionId fileId ->
            ( model
            , Nothing
            , case
                IdArray.get questionId model.noteDrafts
                    |> Maybe.andThen (\draft -> SeqDict.get fileId draft.attachedFiles)
              of
                Just (FileStatus.FileUploaded fileData) ->
                    case fileData.metadata of
                        Just metadata ->
                            ShowAttachedFileInfo
                                { fileName = fileData.fileName
                                , fileSize = fileData.fileSize
                                , metadata = metadata
                                , contentType = fileData.contentType
                                , fileHash = fileData.fileHash
                                }

                        Nothing ->
                            NoOutMsg

                _ ->
                    NoOutMsg
            )

        PressedToggleNotesFileSpoiler questionId { fileId, removeSpoiler } ->
            ( { model
                | noteDrafts =
                    IdArray.update
                        questionId
                        (\draft ->
                            { draft
                                | text =
                                    mapQuestionRichText
                                        localUser.timezone
                                        (User.allUsers localUser)
                                        (if removeSpoiler then
                                            RichText.unspoilerAttachedFile fileId

                                         else
                                            RichText.spoilerAttachedFile fileId
                                        )
                                        draft.text
                            }
                        )
                        model.noteDrafts
              }
            , Nothing
            , NoOutMsg
            )

        PressedRevealScores ->
            ( model, Just FinishedGrouping, NoOutMsg )

        PressedShowNextQuestion ->
            ( model
            , min (revealStepCount setup) (shared.questionsRevealed + 1)
                |> Id.fromInt
                |> ChangedQuestionsRevealed
                |> Just
            , NoOutMsg
            )

        PressedHidePreviousQuestion ->
            ( model
            , max 0 (shared.questionsRevealed - 1) |> Id.fromInt |> ChangedQuestionsRevealed |> Just
            , NoOutMsg
            )

        HoveredResultsGrid userPair ->
            ( { model | gridHovered = Just userPair }, Nothing, NoOutMsg )

        ExitedResultsGrid userPair ->
            ( { model
                | gridHovered =
                    if model.gridHovered == Just userPair then
                        Nothing

                    else
                        model.gridHovered
              }
            , Nothing
            , NoOutMsg
            )

        UserScrolledResults scrollPosition ->
            ( { model
                | scrollPosition = scrollPosition

                -- Reaching the bottom is the reader catching up with the question they were
                -- told about, so the indicator has said what it had to say
                , newQuestionRevealed = model.newQuestionRevealed && scrollPosition /= ScrolledToBottom
              }
            , Nothing
            , NoOutMsg
            )

        PressedNewQuestionRevealed ->
            ( { model | newQuestionRevealed = False }
            , Nothing
            , revealedSectionId shared.questionsRevealed |> ScrollResultsTo
            )

        ReactionMsg target messageViewMsg ->
            case messageViewMsg of
                MessageView.MessageView_MouseEnteredMessage ->
                    ( { model | hoveredResult = Just target }, Nothing, NoOutMsg )

                MessageView.MessageView_MouseExitedMessage ->
                    ( { model
                        | hoveredResult =
                            if model.hoveredResult == Just target then
                                Nothing

                            else
                                model.hoveredResult
                      }
                    , Nothing
                    , NoOutMsg
                    )

                MessageView.MessageViewMsg_PressedReactionEmoji emoji ->
                    ( model, toggleReaction localUser.session.userId shared target emoji |> Just, NoOutMsg )

                MessageView.MessageView_PressedReactionEmoji_Add emoji ->
                    ( model, AddedReaction target emoji |> Just, NoOutMsg )

                MessageView.MessageView_PressedReactionEmoji_Remove emoji ->
                    ( model, RemovedReaction target emoji |> Just, NoOutMsg )

                MessageView.MessageViewMsg_PressedShowReactionEmojiSelector ->
                    ( model, Nothing, OpenReactionEmojiSelector target )

                -- The rest of what a message offers belongs to the conversation it's in, and
                -- an answer isn't in one
                _ ->
                    ( model, Nothing, NoOutMsg )

        PressedImage pressedImageData ->
            ( model, Nothing, ShowImage pressedImageData )

        NoOp ->
            ( model, Nothing, NoOutMsg )


revealStepCount : ValidatedSetup -> Int
revealStepCount setup =
    List.Nonempty.length setup.questions + 1


{-| The part of the results that the given number of reveals has just put on screen. The
first reveal is the scoring explanation and every one after it is a question.
-}
revealedSectionId : Int -> HtmlId
revealedSectionId questionsRevealed =
    if questionsRevealed <= 1 then
        scoringId

    else
        revealedQuestionId (questionsRevealed - 2)


{-| What a change in how many questions are revealed means for the person watching. Someone
sitting at the bottom of the tab is taken on to the question that just turned up, and someone
who has scrolled up is told about it instead so that what they're reading doesn't move out
from under them. The host stepping back to an earlier question isn't a question turning up,
so it does neither.

The id returned is the question to scroll to, when there is scrolling to be done.

-}
questionRevealed : Int -> GameData -> ( GameData, Maybe HtmlId )
questionRevealed questionsRevealed model =
    if questionsRevealed > model.questionsRevealedSeen then
        ( { model
            | questionsRevealedSeen = questionsRevealed
            , newQuestionRevealed = model.scrollPosition /= ScrolledToBottom
          }
        , case model.scrollPosition of
            ScrolledToBottom ->
                revealedSectionId questionsRevealed |> Just

            ScrolledToTop ->
                Nothing

            ScrolledToMiddle ->
                Nothing
        )

    else
        ( { model | questionsRevealedSeen = questionsRevealed }, Nothing )


{-| The answer boxes whose contents changed, so that typing in one doesn't schedule a save
for every other answer as well.
-}
changedInputs : GameData -> GameData -> List Input
changedInputs before after =
    changedDrafts AnswerInput before.answerDrafts after.answerDrafts
        ++ changedDrafts NotesInput before.noteDrafts after.noteDrafts


changedDrafts :
    (Id QuestionId -> Input)
    -> IdArray QuestionId UnvalidatedInput
    -> IdArray QuestionId UnvalidatedInput
    -> List Input
changedDrafts toInput before after =
    IdArray.map
        (\questionId draft ->
            if IdArray.get questionId before == Just draft then
                Nothing

            else
                Just (toInput questionId)
        )
        after
        |> IdArray.toList
        |> List.filterMap identity


{-| What one box is worth saving as, once whoever is writing in it has stopped typing. A box
with nothing in it yet, or one naming a file that hasn't finished uploading, saves as
nothing at all rather than holding the save up.

Questions belong to the setup rather than to a match in progress, so there's nothing to save
for one of those.

-}
saveInputAction : LocalUser -> Input -> GameData -> Maybe Action
saveInputAction localUser input model =
    case input of
        QuestionInput _ ->
            Nothing

        AnswerInput questionId ->
            validatedDraft localUser questionId model.answerDrafts
                |> SubmittedAnswer questionId
                |> Just

        NotesInput questionId ->
            validatedDraft localUser questionId model.noteDrafts
                |> ChangedNotes questionId
                |> Just


validatedDraft : LocalUser -> Id QuestionId -> IdArray QuestionId UnvalidatedInput -> Maybe ValidatedInput
validatedDraft localUser questionId drafts =
    case IdArray.get questionId drafts of
        Just draft ->
            validateInput localUser.timezone (User.allUsers localUser) draft
                |> Result.toMaybe
                |> Maybe.map (\validated -> validated ())

        Nothing ->
            Nothing


{-| Everything the host is allowed to do and nobody else is. The backend replays the same
actions through `updateAction`, so a client that sends one of these without being the host
just has it ignored rather than rejected.
-}
isHost : Id UserId -> ValidatedSetup -> Bool
isHost userId setup =
    userId == setup.createdBy


updateAction : ValidatedSetup -> ActionWithTime -> Shared -> Shared
updateAction setup action shared =
    case action.change of
        SubmittedAnswer questionId answer ->
            case shared.phase of
                Answering ->
                    { shared
                        | answers =
                            SeqDict.update
                                action.userId
                                (\answers ->
                                    Maybe.withDefault
                                        (Array.initialize (List.Nonempty.length setup.questions) (\_ -> Nothing)
                                            |> IdArray.fromArray
                                        )
                                        answers
                                        |> IdArray.set questionId answer
                                        |> Just
                                )
                                shared.answers
                    }

                _ ->
                    shared

        LockedAnswers ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Answering, True ) ->
                    { shared | phase = Grouping, groups = autoGroup setup shared.answers }

                _ ->
                    shared

        UnlockedAnswers ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Grouping, True ) ->
                    { shared | phase = Answering }

                _ ->
                    shared

        ChangedGroup userId questionIndex group ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Grouping, True ) ->
                    { shared | groups = SeqDict.insert ( userId, questionIndex ) group shared.groups }

                _ ->
                    shared

        ChangedNotes questionId notes ->
            case ( shared.phase, isHost action.userId setup ) of
                -- Notes are saved a moment after the host stops typing, so one they were still
                -- writing when they pressed reveal arrives once the reveal has started. There's
                -- nowhere to write one after that, so taking it is better than dropping it.
                ( Answering, _ ) ->
                    shared

                ( _, True ) ->
                    { shared | notes = SeqDict.insert questionId notes shared.notes }

                ( _, False ) ->
                    shared

        FinishedGrouping ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Grouping, True ) ->
                    { shared | phase = Revealing, questionsRevealed = 0 }

                _ ->
                    shared

        AddedReaction target emoji ->
            mapReactions target (SeqDictHelper.addToSet emoji action.userId) shared

        RemovedReaction target emoji ->
            mapReactions target (removeFromReactions emoji action.userId) shared

        ChangedQuestionsRevealed count ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Revealing, True ) ->
                    { shared | questionsRevealed = clamp 0 (revealStepCount setup) (Id.toInt count) }

                _ ->
                    shared


{-| What two answers have to share to count as the same answer. Rendering the text with
no timezone and nobody's name keeps this identical everywhere it's worked out, which is
what matters when the backend and every client have to reach the same grouping.
-}
answerKey : ValidatedInput -> String
answerKey answer =
    RichText.toString Time.utc False SeqDict.empty answer.text
        |> String.trim
        |> String.toLower


{-| The host's starting point for grouping: answers that already match once case and
surrounding whitespace are ignored get the same label.
-}
autoGroup :
    ValidatedSetup
    -> SeqDict (Id UserId) (IdArray QuestionId (Maybe ValidatedInput))
    -> SeqDict ( Id UserId, Id QuestionId ) String
autoGroup setup answers =
    List.range 0 (List.Nonempty.length setup.questions - 1)
        |> List.concatMap
            (\questionIndex ->
                let
                    questionId : Id QuestionId
                    questionId =
                        Id.fromInt questionIndex
                in
                SeqDict.toList answers
                    |> List.filterMap
                        (\( userId, userAnswers ) ->
                            case IdArray.get questionId userAnswers of
                                Just (Just answer) ->
                                    Just ( userId, answerKey answer )

                                _ ->
                                    Nothing
                        )
                    |> List.Extra.gatherEqualsBy Tuple.second
                    |> List.indexedMap
                        (\groupIndex ( first, rest ) ->
                            List.map
                                (\( userId, _ ) -> ( ( userId, questionId ), groupLabel groupIndex ))
                                (first :: rest)
                        )
                    |> List.concat
            )
        |> SeqDict.fromList


groupLabel : Int -> String
groupLabel index =
    Char.fromCode (Char.toCode 'a' + modBy 26 index) |> String.fromChar


{-| Who wrote an answer to at least one question. Someone who joined the channel but never
answered isn't in the running and shouldn't clutter the scoreboard.
-}
players : Shared -> List (Id UserId)
players shared =
    SeqDict.toList shared.answers
        |> List.filterMap
            (\( userId, answers ) ->
                if List.any (\answer -> answer /= Nothing) (IdArray.toList answers) then
                    Just userId

                else
                    Nothing
            )


{-| Scores once `questionCount` questions have been revealed. Each question awards every
player the size of the group their answer landed in, so matching two other people is worth
three points and writing something nobody else thought of is worth one.
-}
scoresThroughQuestion : Int -> Shared -> SeqDict (Id UserId) Int
scoresThroughQuestion questionCount shared =
    List.range 0 (questionCount - 1)
        |> List.foldl
            (\questionIndex scores ->
                List.foldl
                    (\( _, group ) scores2 ->
                        List.foldl
                            (\userId scores3 ->
                                SeqDict.update
                                    userId
                                    (\maybe -> Maybe.withDefault 0 maybe + List.length group |> Just)
                                    scores3
                            )
                            scores2
                            group
                    )
                    scores
                    (groupsForQuestion (Id.fromInt questionIndex) shared)
            )
            (players shared |> List.map (\userId -> ( userId, 0 )) |> SeqDict.fromList)


{-| The players who answered a question, bucketed by the label the host gave their answer.
-}
groupsForQuestion : Id QuestionId -> Shared -> List ( String, List (Id UserId) )
groupsForQuestion questionId shared =
    players shared
        |> List.filterMap
            (\userId ->
                case answerFor userId questionId shared of
                    Just _ ->
                        Just
                            ( SeqDict.get ( userId, questionId ) shared.groups |> Maybe.withDefault ""
                            , userId
                            )

                    Nothing ->
                        Nothing
            )
        |> List.Extra.gatherEqualsBy Tuple.first
        |> List.map
            (\( ( group, userId ), rest ) -> ( group, userId :: List.map Tuple.second rest ))


answerFor : Id UserId -> Id QuestionId -> Shared -> Maybe ValidatedInput
answerFor userId questionId shared =
    case SeqDict.get userId shared.answers of
        Just answers ->
            case IdArray.get questionId answers of
                Just answer ->
                    answer

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


setupView :
    Coord CssPixels
    -> LocalUser
    -> LoggedIn a
    -> SeqDict (Id UserId) FrontendUser
    -> SetupModel
    -> Element SetupMsg
setupView windowSize localUser loggedIn users model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize
    in
    Ui.column
        [ Ui.spacing 16
        , Ui.background MyUi.tabBackground
        , Ui.heightMax (tabBodyHeight False windowSize)
        , Ui.scrollable
        , Ui.heightMin 0
        , Ui.paddingXY 0 16
        ]
        [ Go.setupSection
            isMobile
            (Ui.text "Sheep Questions")
            Nothing
            (Ui.column
                [ Ui.spacing 8 ]
                (List.indexedMap
                    (\index question ->
                        Ui.column
                            []
                            [ Ui.Lazy.lazy5 questionInput localUser loggedIn users index question
                            , case ( model.pressedSubmit, validateInput localUser.timezone users question ) of
                                ( True, Err error ) ->
                                    Ui.el [ Ui.Font.color MyUi.errorColor ] (Ui.text error)

                                _ ->
                                    Ui.none
                            ]
                    )
                    (IdArray.toList model.questions)
                    ++ [ MyUi.secondaryButton
                            (Dom.id "sheepGame_addQuestion")
                            PressedAddQuestion
                            "Add question"
                       ]
                )
            )
        , case model.error of
            Just error ->
                Ui.el [ Ui.Font.color MyUi.errorColor ] (Ui.text error)

            Nothing ->
                Ui.none
        , Go.startOrCancel "sheepGame" isMobile PressedCancel PressedStartGame
        ]


{-| One of the text inputs a sheep game draws. Which one it is says where the emoji picker
opens and which input an emoji or a file reference is put into, which is all the frontend
needs to know about either of them.
-}
type Input
    = QuestionInput (Id QuestionId)
    | AnswerInput (Id QuestionId)
    | NotesInput (Id QuestionId)


inputId : Input -> HtmlId
inputId input =
    case input of
        QuestionInput questionId ->
            Dom.id ("sheepGame_question_" ++ Id.toString questionId)

        AnswerInput questionId ->
            Dom.id ("sheepGame_answer_" ++ Id.toString questionId)

        NotesInput questionId ->
            Dom.id ("sheepGame_notes_" ++ Id.toString questionId)


{-| The box drawn around an input, rather than the textarea inside it. The emoji selector is
placed against this so that it clears the whole input instead of overlapping the bottom of
it.
-}
inputContainerId : Input -> HtmlId
inputContainerId input =
    case input of
        QuestionInput questionId ->
            Dom.id ("sheepGame_questionContainer_" ++ Id.toString questionId)

        AnswerInput questionId ->
            Dom.id ("sheepGame_answerContainer_" ++ Id.toString questionId)

        NotesInput questionId ->
            Dom.id ("sheepGame_notesContainer_" ++ Id.toString questionId)


questionInput :
    LocalUser
    -> LoggedIn a
    -> SeqDict (Id UserId) FrontendUser
    -> Int
    -> UnvalidatedInput
    -> Element SetupMsg
questionInput localUser loggedIn users index question =
    let
        questionId : Id QuestionId
        questionId =
            Id.fromInt index

        htmlId : HtmlId
        htmlId =
            inputId (QuestionInput questionId)

        richText : Maybe (Nonempty (RichText (Id UserId)))
        richText =
            String.Nonempty.fromString question.text
                |> Maybe.map (RichText.fromNonemptyString localUser.timezone users)
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ case NonemptyDict.fromSeqDict question.attachedFiles of
            Just attachedFiles ->
                fileUploadPreview
                    (PressedDeleteAttachedFile questionId)
                    (PressedViewAttachedFileInfo questionId)
                    (PressedToggleAttachedFileSpoiler questionId)
                    richText
                    attachedFiles
                    |> Ui.row
                        [ Ui.spacing 2
                        , Ui.width Ui.shrink
                        ]

            Nothing ->
                Ui.none
        , Ui.row
            [ Ui.spacing 4 ]
            [ Ui.row
                [ Ui.width Ui.shrink, Ui.alignTop, Ui.spacing 4 ]
                [ MessageInput.attachmentButton (Dom.idToString htmlId)
                    |> Ui.map (TypedQuestion questionId)
                , MessageInput.showEmojiSelectorButton (Dom.idToString htmlId)
                    |> Ui.map (TypedQuestion questionId)
                ]
            , MessageInput.textarea
                False
                htmlId
                ""
                (maxQuestionLength - String.length question.text)
                question.text
                richText
                question.attachedFiles
                localUser
                loggedIn
                users
                |> Ui.html
                |> Ui.map (TypedQuestion questionId)
                |> Ui.el
                    (Ui.heightMax 300
                        :: Ui.id (Dom.idToString (inputContainerId (QuestionInput questionId)))
                        :: MessageInput.containerAttributes True
                    )
                |> Ui.el []
            , MyUi.deleteButton
                (Dom.id ("sheepGame_removeQuestion_" ++ String.fromInt index))
                (PressedRemoveQuestion questionId)
                |> Ui.el [ Ui.width Ui.shrink, Ui.alignTop ]
            ]
        ]


{-| The scrollable body of the games tab while a sheep game is being played.
-}
gameViewId : HtmlId
gameViewId =
    Dom.id "sheepGame_tabBody"


revealedQuestionId : Int -> HtmlId
revealedQuestionId index =
    Dom.id ("sheepGame_revealedQuestion_" ++ String.fromInt index)


newQuestionRevealedId : HtmlId
newQuestionRevealedId =
    Dom.id "sheepGame_newQuestionRevealed"


{-| Sits at the bottom of the tab body when a question turned up while the reader was
somewhere further up. Pressing it takes them down to it.
-}
newQuestionRevealedView : Bool -> Element GameMsg
newQuestionRevealedView isMobile =
    MyUi.elButton
        newQuestionRevealedId
        PressedNewQuestionRevealed
        [ Ui.alignBottom
        , Ui.centerX
        , Ui.width Ui.shrink
        , Ui.move { x = 0, y = -16, z = 0 }
        , Ui.paddingXY 12 8
        , Ui.rounded 8
        , Ui.border 1
        , Ui.borderColor MyUi.buttonBorder
        , Ui.background MyUi.buttonBackground
        , Ui.Font.color MyUi.font1
        , Ui.pointer
        , MyUi.hover isMobile [ Ui.Anim.backgroundColor MyUi.highlightedBorder ]
        ]
        (Ui.text "New question revealed!")


tabBodyHeight : Bool -> Coord CssPixels -> Int
tabBodyHeight isAnsweringQuestions windowSize =
    if isAnsweringQuestions && MyUi.isMobileAlt windowSize then
        Coord.yRaw windowSize - MyUi.channelHeaderHeight

    else
        min
            (Coord.yRaw windowSize - (MyUi.channelHeaderHeight + 150))
            (round (toFloat (Coord.yRaw windowSize) * 0.8) - MyUi.channelHeaderHeight)


paddingX : Bool -> Int
paddingX isMobile =
    if isMobile then
        8

    else
        16


gameView :
    Time.Posix
    -> Coord CssPixels
    -> Bool
    -> LocalUser
    -> Drag
    -> LoggedIn a
    -> ValidatedSetup
    -> Shared
    -> GameData
    -> Element GameMsg
gameView time windowSize showMemberTab localUser drag loggedIn setup shared model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize

        maxWidth =
            1000

        contentWidth : Int
        contentWidth =
            MyUi.conversationWidthIgnoreScrollbar windowSize showMemberTab - paddingX isMobile * 2 |> min maxWidth

        isHost2 =
            isHost localUser.session.userId setup
    in
    Ui.el
        [ Ui.height (Ui.px (tabBodyHeight (shared.phase == Answering) windowSize))
        , if model.newQuestionRevealed && not isHost2 then
            Ui.inFront (newQuestionRevealedView isMobile)

          else
            Ui.noAttr
        , case ( shared.phase, isHost2 ) of
            ( Revealing, True ) ->
                Ui.row
                    [ Ui.spacing 8
                    , Ui.padding 8
                    , Ui.attrIf (not isMobile) (Ui.width Ui.shrink)
                    , Ui.background MyUi.background1
                    , Ui.alignBottom
                    ]
                    [ Ui.el
                        [ if shared.questionsRevealed == 0 then
                            Ui.opacity 0.5

                          else
                            Ui.opacity 1
                        , Ui.width Ui.shrink
                        ]
                        (MyUi.secondaryButtonTall
                            (Dom.id "sheepGame_hidePreviousQuestion")
                            PressedHidePreviousQuestion
                            "Back"
                        )
                    , Ui.el
                        [ if shared.questionsRevealed > List.Nonempty.length setup.questions then
                            Ui.opacity 0.5

                          else
                            Ui.opacity 1
                        , Ui.width Ui.shrink
                        ]
                        (MyUi.simpleButton
                            (Dom.id "sheepGame_showNextQuestion")
                            PressedShowNextQuestion
                            (Ui.text "Show next question")
                        )
                    ]
                    |> Ui.inFront

            _ ->
                Ui.noAttr
        ]
        (Ui.el
            [ Ui.background MyUi.background1
            , MyUi.scrollable (MyUi.canScroll (MyUi.isMobileAlt windowSize) drag)
            , Ui.height (Ui.px (tabBodyHeight (shared.phase == Answering) windowSize))
            , Ui.id (Dom.idToString gameViewId)
            , Ui.Events.on "scroll" (Scroll.decodeScrollToBottom UserScrolledResults model.scrollPosition)

            -- Ui.onRight and friends are given a z-index by elm-ui while Ui.inFront isn't, so
            -- without this the scores drawn beside the scoreboard bars come out on top of the
            -- reveal buttons placed in front of this. Keeping their z-index inside this div
            -- means everything scrolling here stays behind those buttons.
            , MyUi.htmlStyle "isolation" "isolate"
            ]
            (case shared.phase of
                Answering ->
                    Ui.column
                        [ MyUi.htmlStyle
                            "padding"
                            ("16px "
                                ++ String.fromInt (paddingX isMobile)
                                ++ "px calc(16px + "
                                ++ MyUi.insetBottom
                                ++ ") "
                                ++ String.fromInt (paddingX isMobile)
                                ++ "px"
                            )
                        , Ui.centerX
                        , Ui.widthMax maxWidth
                        , Ui.spacing 16
                        ]
                        (answeringView time contentWidth localUser loggedIn setup shared model)

                Grouping ->
                    Ui.column
                        [ Ui.paddingXY (paddingX isMobile) 16, Ui.centerX, Ui.widthMax maxWidth, Ui.spacing 16 ]
                        (groupingView time contentWidth localUser loggedIn setup shared model)

                Revealing ->
                    Ui.column
                        [ Ui.paddingWith
                            { left = 0
                            , right = 0
                            , top = 16
                            , bottom =
                                if isHost2 then
                                    -- Approximate padding for show next question button at bottom
                                    16 + 56

                                else
                                    16
                            }
                        , Ui.centerX
                        , Ui.widthMax maxWidth
                        , Ui.spacing 16
                        ]
                        (revealingView isMobile time contentWidth localUser setup shared model)
            )
        )


{-| Questions and answers are drawn the same way a message is, so that a file attached to a
question shows up as the image or video it is rather than as a placeholder.

Pressing an image opens it full size, which the frontend does since it's the one holding the
viewer. Revealing a spoiler still does nothing: what has been revealed is kept per message
by the frontend and a question isn't one.

-}
contentView :
    Time.Posix
    -> Int
    -> LocalUser
    -> HtmlId
    -> SeqDict (Id FileId) FileData
    -> Nonempty (RichText (Id UserId))
    -> Element GameMsg
contentView time contentWidth localUser htmlId attachedFiles content =
    RichText.view
        htmlId
        contentWidth
        (\_ -> NoOp)
        (\_ -> NoOp)
        PressedImage
        { domainWhitelist = localUser.user.domainWhitelist
        , revealedSpoilers = SeqSet.empty
        , users = User.allUsers localUser
        , attachedFiles = attachedFiles
        , stickers = localUser.stickers
        , customEmojis = localUser.customEmojis
        , animationMode = Sticker.LoopAFewTimesOnLoad
        , timezone = localUser.timezone
        , time = time
        , drawings = SeqDict.empty
        , embedDrawings = SeqDict.empty
        , drawingUserColor = \_ -> UserColor.default
        , isSelectingAnchor = False
        , devicePixelRatio = localUser.devicePixelRatio
        , isHovered = False
        }
        Array.empty
        content
        |> Html.div [ Html.Attributes.style "white-space" "pre-wrap", Html.Attributes.id (Dom.idToString htmlId) ]
        |> Ui.html


{-| Something someone wrote, with their name and picture beside it the way a message has.
-}
messageWithProfile : Id UserId -> LocalUser -> Element msg -> Element msg
messageWithProfile userId localUser content =
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.alignTop, Ui.width Ui.shrink ] (User.profileImage (User.getUser userId localUser))
        , Ui.column
            []
            [ User.toStringAlt userId localUser
                |> Ui.text
                |> Ui.el [ Ui.Font.bold ]
            , content
            ]
        ]


answeringView :
    Time.Posix
    -> Int
    -> LocalUser
    -> LoggedIn a
    -> ValidatedSetup
    -> Shared
    -> GameData
    -> List (Element GameMsg)
answeringView time contentWidth localUser loggedIn setup shared model =
    let
        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId

        answerContentWidth =
            contentWidth - (User.profileImageSize + 8)
    in
    [ Ui.el
        [ Ui.Font.bold, Ui.Font.size 20 ]
        (if isHost localUser.session.userId setup then
            Ui.text "Waiting on people's answers"

         else
            Ui.text "Answer like everyone else"
        )
    , Ui.column
        [ Ui.spacing 8 ]
        [ Ui.text "You score a point for every player who writes a sufficiently* similar answer to you."
        , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text "*The game host decides what counts as sufficiently similar.")
        ]
    , Ui.column
        [ Ui.spacing 16 ]
        (List.Nonempty.toList setup.questions
            |> List.indexedMap
                (\index question ->
                    let
                        questionId : Id QuestionId
                        questionId =
                            Id.fromInt index
                    in
                    Ui.column
                        [ Ui.spacing 4 ]
                        [ contentView
                            time
                            contentWidth
                            localUser
                            (Dom.id ("sheepGame_answeringQuestion_" ++ Id.toString questionId))
                            question.attachedFiles
                            question.text
                        , if isHost localUser.session.userId setup then
                            let
                                answers : List (Element GameMsg)
                                answers =
                                    List.map
                                        (\( answeredBy, answers2 ) ->
                                            case IdArray.get questionId answers2 of
                                                Just (Just answer) ->
                                                    messageWithProfile
                                                        answeredBy
                                                        localUser
                                                        (contentView
                                                            time
                                                            answerContentWidth
                                                            localUser
                                                            (Dom.id
                                                                ("sheepGame_answerPreview_"
                                                                    ++ Id.toString questionId
                                                                    ++ "_"
                                                                    ++ Id.toString answeredBy
                                                                )
                                                            )
                                                            answer.attachedFiles
                                                            answer.text
                                                        )

                                                _ ->
                                                    Ui.el [ Ui.Font.italic ] (Ui.text "No answered")
                                        )
                                        (SeqDict.toList shared.answers)
                            in
                            case answers of
                                [] ->
                                    Ui.el [ Ui.Font.italic, Ui.Font.color MyUi.font3 ] (Ui.text "No answers yet")

                                _ ->
                                    Ui.column [] answers

                          else
                            answerInput
                                localUser
                                loggedIn
                                questionId
                                (IdArray.get questionId model.answerDrafts
                                    |> Maybe.withDefault { text = "", attachedFiles = SeqDict.empty }
                                )
                        ]
                )
        )
    , if isHost currentUserId setup then
        MyUi.secondaryButton
            (Dom.id "sheepGame_lockAnswers")
            PressedLockAnswers
            "Lock answers and tally score"

      else
        Ui.text "Your answers are saved automatically!"
    , Ui.el
        [ Ui.Font.color MyUi.font3 ]
        (Ui.text (answeredCountText (players shared |> List.length)))
    ]


{-| An answer is written in the same input a message is, so that what someone types is
drawn the way it will be once everyone's answers are compared.
-}
answerInput : LocalUser -> LoggedIn a -> Id QuestionId -> UnvalidatedInput -> Element GameMsg
answerInput localUser loggedIn questionId answer =
    let
        htmlId : HtmlId
        htmlId =
            inputId (AnswerInput questionId)

        users : SeqDict (Id UserId) FrontendUser
        users =
            User.allUsers localUser

        richText : Maybe (Nonempty (RichText (Id UserId)))
        richText =
            String.Nonempty.fromString answer.text
                |> Maybe.map (RichText.fromNonemptyString localUser.timezone users)
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ case NonemptyDict.fromSeqDict answer.attachedFiles of
            Just attachedFiles ->
                fileUploadPreview
                    (PressedDeleteAnswerFile questionId)
                    (PressedViewAnswerFileInfo questionId)
                    (PressedToggleAnswerFileSpoiler questionId)
                    richText
                    attachedFiles
                    |> Ui.row
                        [ Ui.spacing 2
                        , Ui.width Ui.shrink
                        ]

            Nothing ->
                Ui.none
        , Ui.row
            [ Ui.spacing 4 ]
            [ Ui.row
                [ Ui.width Ui.shrink, Ui.alignTop, Ui.spacing 4 ]
                [ MessageInput.attachmentButton (Dom.idToString htmlId)
                    |> Ui.map (TypedAnswer questionId)
                , MessageInput.showEmojiSelectorButton (Dom.idToString htmlId)
                    |> Ui.map (TypedAnswer questionId)
                ]
            , MessageInput.textarea
                True
                htmlId
                "Answer here"
                (maxAnswerLength - String.length answer.text)
                answer.text
                richText
                answer.attachedFiles
                localUser
                loggedIn
                users
                |> Ui.html
                |> Ui.map (TypedAnswer questionId)
                |> Ui.el
                    (Ui.heightMax 200
                        :: Ui.id (Dom.idToString (inputContainerId (AnswerInput questionId)))
                        :: MessageInput.containerAttributes True
                    )
                |> Ui.el []
            ]
        ]


answeredCountText : Int -> String
answeredCountText count =
    if count == 1 then
        "1 player has answered so far"

    else
        String.fromInt count ++ " players have answered so far"


{-| The host decides which answers count as the same thing. Everyone else waits.
-}
groupingView :
    Time.Posix
    -> Int
    -> LocalUser
    -> LoggedIn a
    -> ValidatedSetup
    -> Shared
    -> GameData
    -> List (Element GameMsg)
groupingView time contentWidth localUser loggedIn setup shared model =
    if isHost localUser.session.userId setup then
        [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Group the answers")
        , Ui.Prose.paragraph
            [ Ui.Font.color MyUi.font3 ]
            [ Ui.text "Answers sharing a letter score together. Change a letter to split an answer off or to merge it with another." ]
        , Ui.column
            [ Ui.spacing 16 ]
            (List.Nonempty.toList setup.questions
                |> List.indexedMap (groupingQuestionView time contentWidth localUser loggedIn shared model)
            )
        , Ui.row
            [ Ui.spacing 8 ]
            [ MyUi.secondaryButtonTall
                (Dom.id "sheepGame_unlockAnswers")
                PressedUnlockAnswers
                "Unlock answers"
            , MyUi.simpleButton
                (Dom.id "sheepGame_revealScores")
                PressedRevealScores
                (Ui.text "Reveal scores")
            ]
        ]

    else
        [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Answers are locked")
        , Ui.Prose.paragraph
            [ Ui.Font.color MyUi.font3 ]
            [ Ui.text "The host is grouping the answers together. The scores show up here once they're done." ]
        ]


groupingQuestionView :
    Time.Posix
    -> Int
    -> LocalUser
    -> LoggedIn a
    -> Shared
    -> GameData
    -> Int
    -> ValidatedInput
    -> Element GameMsg
groupingQuestionView time contentWidth localUser loggedIn shared model questionIndex question =
    let
        questionId : Id QuestionId
        questionId =
            Id.fromInt questionIndex
    in
    Ui.column
        [ Ui.spacing 8 ]
        [ Ui.el
            [ Ui.Font.weight 600 ]
            (contentView
                time
                contentWidth
                localUser
                (Dom.id ("sheepGame_groupingQuestion_" ++ Id.toString questionId))
                question.attachedFiles
                question.text
            )
        , Ui.column
            [ Ui.spacing 4 ]
            (players shared
                |> List.filterMap
                    (\userId ->
                        Maybe.map
                            (groupingAnswerView time contentWidth localUser questionId userId shared)
                            (answerFor userId questionId shared)
                    )
            )
        , Ui.column
            [ Ui.spacing 2 ]
            [ Ui.el
                [ Ui.Font.color MyUi.font3, Ui.Font.size 14 ]
                (Ui.text "Notes")
            , notesInput
                localUser
                loggedIn
                questionId
                (IdArray.get questionId model.noteDrafts |> Maybe.withDefault emptyInput)
            ]
        ]


{-| The host's comment on a question, written in the same input an answer is so that it can
say the same kinds of things.
-}
notesInput : LocalUser -> LoggedIn a -> Id QuestionId -> UnvalidatedInput -> Element GameMsg
notesInput localUser loggedIn questionId notes =
    let
        htmlId : HtmlId
        htmlId =
            inputId (NotesInput questionId)

        users : SeqDict (Id UserId) FrontendUser
        users =
            User.allUsers localUser

        richText : Maybe (Nonempty (RichText (Id UserId)))
        richText =
            String.Nonempty.fromString notes.text
                |> Maybe.map (RichText.fromNonemptyString localUser.timezone users)
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ case NonemptyDict.fromSeqDict notes.attachedFiles of
            Just attachedFiles ->
                fileUploadPreview
                    (PressedDeleteNotesFile questionId)
                    (PressedViewNotesFileInfo questionId)
                    (PressedToggleNotesFileSpoiler questionId)
                    richText
                    attachedFiles
                    |> Ui.row
                        [ Ui.spacing 2
                        , Ui.width Ui.shrink
                        ]

            Nothing ->
                Ui.none
        , Ui.row
            [ Ui.spacing 8 ]
            [ MessageInput.attachmentButton (Dom.idToString htmlId)
                |> Ui.map (TypedNotes questionId)
            , MessageInput.showEmojiSelectorButton (Dom.idToString htmlId)
                |> Ui.map (TypedNotes questionId)
            , MessageInput.textarea
                True
                htmlId
                ""
                (maxNoteLength - String.length notes.text)
                notes.text
                richText
                notes.attachedFiles
                localUser
                loggedIn
                users
                |> Ui.html
                |> Ui.map (TypedNotes questionId)
                |> Ui.el
                    (Ui.heightMax 200
                        :: Ui.id (Dom.idToString (inputContainerId (NotesInput questionId)))
                        :: MessageInput.containerAttributes True
                    )
                |> Ui.el []
            ]
        ]


groupingAnswerView :
    Time.Posix
    -> Int
    -> LocalUser
    -> Id QuestionId
    -> Id UserId
    -> Shared
    -> ValidatedInput
    -> Element GameMsg
groupingAnswerView time contentWidth localUser questionId userId shared answer =
    let
        groupLabel2 : { element : Element GameMsg, id : Ui.Input.Label }
        groupLabel2 =
            MyUi.label
                (Dom.id ("sheepGame_group_" ++ Id.toString questionId ++ "_" ++ Id.toString userId))
                []
                (Ui.text "Group")
    in
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.width (Ui.px 40) ] groupLabel2.element
        , Ui.row
            [ Ui.alignTop, Ui.spacing 8, Ui.width Ui.shrink, MyUi.noShrinking ]
            [ Ui.el
                [ Ui.width (Ui.px 48) ]
                (Ui.Input.text
                    [ Ui.border 1
                    , Ui.borderColor MyUi.inputBorder
                    , Ui.background MyUi.inputBackground
                    , Ui.rounded 4
                    , Ui.paddingXY 8 4
                    ]
                    { onChange = TypedGroup userId questionId
                    , text = SeqDict.get ( userId, questionId ) shared.groups |> Maybe.withDefault ""
                    , placeholder = Nothing
                    , label = groupLabel2.id
                    }
                )
            , Ui.el
                [ Ui.Font.weight 600, Ui.width Ui.shrink, MyUi.noShrinking ]
                (Ui.text (User.toStringAlt userId localUser))
            ]
        , contentView
            time
            contentWidth
            localUser
            (Dom.id ("sheepGame_groupingAnswer_" ++ Id.toString questionId ++ "_" ++ Id.toString userId))
            answer.attachedFiles
            answer.text
        ]


{-| Which way someone moved on the scoreboard when a question was revealed.
-}
type RankChange
    = RankUp
    | RankDown
    | RankUnchanged


type alias AnswerResult =
    { userId : Id UserId
    , answer : Maybe ValidatedInput
    , group : String
    , score : Int
    , rankChange : RankChange
    }


type alias QuestionResult =
    { question : ValidatedInput
    , notes : Maybe ValidatedInput
    , answers : List AnswerResult
    }


{-| Change the reactions on whichever answer or note the target names, leaving everything
alone when it names something that isn't there.
-}
mapReactions : ReactionTarget -> (Reactions -> Reactions) -> Shared -> Shared
mapReactions target mapFunc shared =
    case target of
        AnswerReaction userId questionId ->
            { shared
                | answers =
                    SeqDict.updateIfExists
                        userId
                        (IdArray.update questionId (Maybe.map (\answer -> { answer | reactions = mapFunc answer.reactions })))
                        shared.answers
            }

        NotesReaction questionId ->
            { shared
                | notes =
                    SeqDict.updateIfExists
                        questionId
                        (Maybe.map (\notes -> { notes | reactions = mapFunc notes.reactions }))
                        shared.notes
            }


{-| An emoji nobody is left reacting with is dropped, the same as it is on a message.
-}
removeFromReactions : EmojiOrCustomEmoji -> Id UserId -> Reactions -> Reactions
removeFromReactions emoji userId reactions =
    SeqDict.update
        emoji
        (Maybe.andThen
            (\users -> NonemptySet.toSeqSet users |> SeqSet.remove userId |> NonemptySet.fromSeqSet)
        )
        reactions


{-| Pressing a reaction that's already yours takes it back, which is what one press of the
same emoji does on a message too.
-}
toggleReaction : Id UserId -> Shared -> ReactionTarget -> EmojiOrCustomEmoji -> Action
toggleReaction userId shared target emoji =
    let
        reactions : Reactions
        reactions =
            case target of
                AnswerReaction answeredBy questionId ->
                    SeqDict.get answeredBy shared.answers
                        |> Maybe.andThen (IdArray.get questionId)
                        |> Maybe.andThen identity
                        |> Maybe.map .reactions
                        |> Maybe.withDefault SeqDict.empty

                NotesReaction questionId ->
                    SeqDict.get questionId shared.notes
                        |> Maybe.andThen identity
                        |> Maybe.map .reactions
                        |> Maybe.withDefault SeqDict.empty
    in
    case SeqDict.get emoji reactions of
        Just users ->
            if NonemptySet.member userId users then
                RemovedReaction target emoji

            else
                AddedReaction target emoji

        Nothing ->
            AddedReaction target emoji


{-| Everything the results screen has to say about a match: what everyone answered to each
question, where that left them on the scoreboard, and who ends up on top.

Scores are the running totals as each question is revealed, so the bars grow through the
reveal. They're all measured against the score the winner finishes on, which is why the
last question's bar is the only one that reaches the end.

-}
resultsData :
    ValidatedSetup
    -> Shared
    -> { maxPoints : Int, questions : List QuestionResult, winners : List (Id UserId) }
resultsData setup shared =
    let
        finalScores : SeqDict (Id UserId) Int
        finalScores =
            scoresThroughQuestion (List.Nonempty.length setup.questions) shared

        maxPoints : Int
        maxPoints =
            SeqDict.values finalScores |> List.maximum |> Maybe.withDefault 0

        everyone : List (Id UserId)
        everyone =
            players shared
    in
    { maxPoints = maxPoints
    , winners =
        SeqDict.toList finalScores
            |> List.filterMap
                (\( userId, score ) ->
                    if score == maxPoints then
                        Just userId

                    else
                        Nothing
                )
    , questions =
        List.Nonempty.toList setup.questions
            |> List.indexedMap
                (\index question ->
                    let
                        questionId : Id QuestionId
                        questionId =
                            Id.fromInt index

                        before : SeqDict (Id UserId) Int
                        before =
                            scoresThroughQuestion index shared

                        after : SeqDict (Id UserId) Int
                        after =
                            scoresThroughQuestion (index + 1) shared
                    in
                    { question = question
                    , notes = SeqDict.get questionId shared.notes |> Maybe.withDefault Nothing
                    , answers =
                        List.map
                            (\userId ->
                                { userId = userId
                                , answer = answerFor userId questionId shared
                                , group = SeqDict.get ( userId, questionId ) shared.groups |> Maybe.withDefault ""
                                , score = SeqDict.get userId after |> Maybe.withDefault 0
                                , rankChange =
                                    if index == 0 then
                                        RankUnchanged

                                    else
                                        case compare (placeIn userId before) (placeIn userId after) of
                                            LT ->
                                                RankUp

                                            GT ->
                                                RankDown

                                            EQ ->
                                                RankUnchanged
                                }
                            )
                            everyone
                    }
                )
    }


{-| How many players someone is ahead of. Two players on the same score are put in a fixed
order rather than sharing a place, so that nobody's rank appears to move when it didn't.
-}
placeIn : Id UserId -> SeqDict (Id UserId) Int -> Int
placeIn userId scores =
    let
        score : Int
        score =
            SeqDict.get userId scores |> Maybe.withDefault 0
    in
    SeqDict.toList scores
        |> List.filter
            (\( otherId, otherScore ) ->
                (otherScore < score)
                    || (otherScore == score && Id.toInt userId < Id.toInt otherId)
            )
        |> List.length


revealingView : Bool -> Time.Posix -> Int -> LocalUser -> ValidatedSetup -> Shared -> GameData -> List (Element GameMsg)
revealingView isMobile time contentWidth localUser setup shared model =
    let
        questionCount : Int
        questionCount =
            List.Nonempty.length setup.questions

        results : { maxPoints : Int, questions : List QuestionResult, winners : List (Id UserId) }
        results =
            resultsData setup shared

        padding =
            Ui.paddingXY (paddingX isMobile) 0
    in
    [ Ui.el
        [ Ui.Font.bold
        , Ui.Font.size 28
        , padding
        , Ui.Font.color MyUi.font2
        , Ui.attrIf isMobile Ui.Font.center
        ]
        (Ui.text "Sheep game results")
    , if shared.questionsRevealed == 0 then
        Ui.column
            [ Ui.Font.size 20
            , Ui.Font.center
            , Ui.padding 16
            , MyUi.fadeIn
            , padding
            , Ui.spacing 16
            ]
            [ Ui.image
                [ Ui.widthMax 502 ]
                { source = "/sheep-game.webp"
                , description = "A sheep with a laptop and wearing headphones"
                , onLoad = Nothing
                }
            , Ui.text "Stay tuned. The results will be revealed shortly."
            ]

      else
        Ui.column
            [ Ui.spacing 32 ]
            (Ui.column
                [ Ui.spacing 8, Ui.id (Dom.idToString scoringId), MyUi.fadeIn, padding ]
                [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Scoring")
                , Ui.column
                    [ Ui.spacing 12, Ui.padding 8, Ui.Font.color MyUi.font3 ]
                    [ Ui.text "For each question you get points equal to the number of people who picked the same answer as you (including yourself). For example, if you pick a unique answer, you get 1 point. If you and two others pick the same answer, you three get 3 points."
                    , Ui.text "The person with the most points at the end wins!"
                    ]
                ]
                :: List.indexedMap
                    (resultsQuestionView isMobile time contentWidth localUser setup model.hoveredResult results.maxPoints)
                    (List.take (shared.questionsRevealed - 1) results.questions)
            )
    , if shared.questionsRevealed > questionCount then
        Ui.column
            [ Ui.spacing 32
            , Ui.paddingWith { left = paddingX isMobile, right = paddingX isMobile, top = 32, bottom = 0 }
            , MyUi.fadeIn
            ]
            [ Ui.el
                [ Ui.height (Ui.px 2), Ui.background MyUi.border1 ]
                Ui.none
            , finalResultsView localUser results.winners
            , if SeqDict.size shared.answers > 2 then
                Ui.column
                    [ Ui.spacing 16 ]
                    [ Ui.el
                        [ Ui.Font.size 20, Ui.Font.bold, Ui.Font.center ]
                        (Ui.text "Statistics: Which players think most alike?")
                    , resultsGridView isMobile localUser setup shared model.gridHovered
                    ]

              else
                Ui.none
            , Ui.el
                [ Ui.Font.size 12, Ui.Font.center, Ui.Font.color MyUi.font3 ]
                (Ui.text "No sheep were impersonated in the playing of this game.")
            ]

      else
        Ui.none
    ]


scoringId : HtmlId
scoringId =
    Dom.id "sheepGame_scoring"


resultsQuestionView :
    Bool
    -> Time.Posix
    -> Int
    -> LocalUser
    -> ValidatedSetup
    -> Maybe ReactionTarget
    -> Int
    -> Int
    -> QuestionResult
    -> Element GameMsg
resultsQuestionView isMobile time contentWidth localUser setup hoveredResult maxPoints index result =
    let
        numberWidth : number
        numberWidth =
            if index < 9 then
                20

            else
                30

        numberSpacing : number
        numberSpacing =
            6
    in
    Ui.column
        [ Ui.spacing 8, Ui.paddingXY 0 16, MyUi.fadeIn ]
        [ Ui.row
            [ Ui.Font.size 20, Ui.spacing numberSpacing, Ui.paddingXY (paddingX isMobile) 0 ]
            [ Ui.el
                [ Ui.width (Ui.px numberWidth)
                , Ui.alignTop
                , Ui.Font.bold
                ]
                (Ui.text (String.fromInt (index + 1) ++ ". "))
            , contentView
                time
                (contentWidth - (numberWidth + numberSpacing))
                localUser
                (revealedQuestionId index)
                result.question.attachedFiles
                result.question.text
            ]
        , Ui.column
            [ Ui.spacing 16 ]
            [ answerGroupsView isMobile time localUser contentWidth hoveredResult (Id.fromInt index) result.answers
            , scoreTableView isMobile localUser maxPoints result.answers
            , case result.notes of
                Nothing ->
                    Ui.none

                Just notes ->
                    messageWithProfile
                        setup.createdBy
                        localUser
                        (contentView
                            time
                            contentWidth
                            localUser
                            (Dom.id ("sheepGame_questionNotes_" ++ String.fromInt index))
                            notes.attachedFiles
                            notes.text
                        )
                        |> reactableResult
                            (paddingX isMobile)
                            localUser
                            contentWidth
                            (NotesReaction (Id.fromInt index))
                            hoveredResult
                            notes.reactions
            ]
        ]


userColor : Id UserId -> LocalUser -> Ui.Color
userColor userId local =
    case User.getUser userId local of
        Just user ->
            UserColor.toColor user.color

        Nothing ->
            UserColor.toColor UserColor.default


answerGroupPaddingX =
    8


answerGroupsView :
    Bool
    -> Time.Posix
    -> LocalUser
    -> Int
    -> Maybe ReactionTarget
    -> Id QuestionId
    -> List AnswerResult
    -> Element GameMsg
answerGroupsView isMobile time localUser contentWidth hoveredResult questionId answers =
    List.filterMap
        (\answerResult ->
            Maybe.map (\answer -> ( answerResult.userId, answerResult.group, answer )) answerResult.answer
        )
        answers
        |> List.Extra.gatherEqualsBy (\( _, group, _ ) -> group)
        |> List.sortBy (\( _, rest ) -> List.length rest)
        |> List.map
            (\( first, rest ) ->
                List.map
                    (\( userId, _, answer ) ->
                        (if RichText.hasLargeContent answer.text then
                            Ui.column
                                [ Ui.spacing 8, Ui.widthMin 200 ]

                         else
                            Ui.row
                                [ Ui.spacing 8, Ui.widthMin 200 ]
                        )
                            [ Ui.el
                                [ Ui.widthMax (toFloat contentWidth * 0.5 |> round)
                                , Ui.width Ui.shrink
                                , Ui.Font.bold
                                , Ui.Font.color (userColor userId localUser)
                                , Ui.alignTop
                                , Ui.clipWithEllipsis
                                ]
                                (Ui.text (User.toStringAlt userId localUser))
                            , contentView
                                time
                                (min 300 (contentWidth - answerGroupPaddingX * 2))
                                localUser
                                (Dom.id ("sheepGame_answerReveal_" ++ Id.toString questionId ++ "_" ++ Id.toString userId))
                                answer.attachedFiles
                                answer.text
                            ]
                            |> reactableResult
                                answerGroupPaddingX
                                localUser
                                contentWidth
                                (AnswerReaction userId questionId)
                                hoveredResult
                                answer.reactions
                    )
                    (first :: rest)
                    |> Ui.column
                        [ MyUi.htmlStyle
                            "outline"
                            ("solid "
                                ++ String.fromInt answerGroupOutlineWidth
                                ++ "px "
                                ++ MyUi.colorToStyle answerGroupOutlineColor
                            )
                        , MyUi.htmlStyle "outline-offset" (String.fromInt answerGroupOutlineOffset ++ "px")
                        , Ui.rounded 3
                        , Ui.width Ui.shrink
                        , Ui.background MyUi.background2
                        ]
            )
        |> Ui.column
            [ Ui.paddingWith
                { left = paddingX isMobile + answerGroupOutlineWidth + answerGroupOutlineOffset
                , right = paddingX isMobile
                , top = 0
                , bottom = 0
                }
            ]


answerGroupOutlineWidth : number
answerGroupOutlineWidth =
    2


answerGroupOutlineOffset : number
answerGroupOutlineOffset =
    -1


answerGroupOutlineColor : Ui.Color
answerGroupOutlineColor =
    Ui.rgb 76 80 100


{-| What an answer or a note is called on the results screen, which is what the reactions on
it hang off.
-}
reactionTargetId : ReactionTarget -> HtmlId
reactionTargetId target =
    case target of
        AnswerReaction userId questionId ->
            Dom.id ("sheepGame_revealedAnswer_" ++ Id.toString questionId ++ "_" ++ Id.toString userId)

        NotesReaction questionId ->
            Dom.id ("sheepGame_revealedNotes_" ++ Id.toString questionId)


{-| An answer or a note, drawn with the reactions it has and, while the pointer is over it,
the menu for adding one. That menu is all that's on offer: editing, replying and the rest of
what a message's menu does belong to the conversation a message is in.
-}
reactableResult : Int -> LocalUser -> Int -> ReactionTarget -> Maybe ReactionTarget -> Reactions -> Element GameMsg -> Element GameMsg
reactableResult paddingX2 localUser contentWidth target hoveredResult reactions content =
    let
        isHovered : Bool
        isHovered =
            hoveredResult == Just target
    in
    Ui.column
        [ Ui.id (Dom.idToString (reactionTargetId target))
        , Ui.paddingXY paddingX2 4
        , Ui.spacing 4
        , Ui.attrIf isHovered (Ui.background MyUi.hoverHighlight)
        , Ui.Events.onMouseEnter (ReactionMsg target MessageView.MessageView_MouseEnteredMessage)
        , Ui.Events.onMouseLeave (ReactionMsg target MessageView.MessageView_MouseExitedMessage)
        , if isHovered then
            MessageView.reactionsMiniViewNearEdge
                localUser.user
                localUser.user.availableCustomEmojis
                localUser.customEmojis
                |> Ui.map (ReactionMsg target)
                |> Ui.inFront

          else
            Ui.noAttr
        ]
        (content
            :: (case
                    MessageView.reactionEmojiView
                        localUser.emojiData
                        (if isHovered then
                            MessageView.ReactionsHovered

                         else
                            MessageView.ReactionsNotHovered
                        )
                        localUser.session.userId
                        localUser.customEmojis
                        (User.allUsers localUser)
                        Sticker.LoopAFewTimesOnLoad
                        (contentWidth - paddingX2 * 2)
                        reactions
                of
                    Just reactionRow ->
                        [ Ui.map (ReactionMsg target) reactionRow ]

                    Nothing ->
                        []
               )
        )


scoreTableView : Bool -> LocalUser -> Int -> List AnswerResult -> Element msg
scoreTableView isMobile localUser maxPoints answers =
    List.sortWith
        (\a b ->
            case compare b.score a.score of
                EQ ->
                    compare (Id.toInt a.userId) (Id.toInt b.userId)

                order ->
                    order
        )
        answers
        |> List.map (scoreRowView localUser maxPoints)
        |> Ui.column [ Ui.spacing 2, Ui.Font.bold, Ui.paddingXY (paddingX isMobile) 0 ]


scoreRowView : LocalUser -> Int -> AnswerResult -> Element msg
scoreRowView localUser maxPoints answerResult =
    let
        { userId, score, rankChange } =
            answerResult

        filled : Int
        filled =
            if maxPoints <= 0 then
                0

            else
                round (toFloat score / toFloat maxPoints * 1000)
    in
    Ui.row
        [ Ui.spacing 1 ]
        [ User.smallProfileImage (User.getUser userId localUser)
        , Ui.row
            [ Ui.height Ui.fill ]
            [ Ui.el
                [ Ui.width (Ui.portion filled)
                , Ui.height Ui.fill
                , Ui.paddingWith { left = 6, right = 4, top = 0, bottom = 0 }
                , Ui.Font.color GuildIcon.iconFontColor
                , Ui.roundedWith
                    { topLeft = 0
                    , topRight = User.smallProfileImageRounding
                    , bottomLeft = 0
                    , bottomRight = User.smallProfileImageRounding
                    }
                , Ui.background (userColor userId localUser)
                , Ui.onRight
                    (Ui.row
                        [ Ui.width Ui.shrink, Ui.move (Ui.right 8), Ui.centerY, Ui.spacing 4, Ui.Font.color MyUi.font1 ]
                        [ Ui.text (String.fromInt score)
                        , case rankChange of
                            RankUp ->
                                Ui.el [ Ui.Font.color (Ui.rgb 25 230 25), Ui.move { x = 0, y = -1, z = 0 } ] (Ui.text "▲")

                            RankDown ->
                                Ui.el [ Ui.Font.color (Ui.rgb 230 25 25), Ui.move { x = 0, y = -1, z = 0 } ] (Ui.text "▼")

                            RankUnchanged ->
                                Ui.none
                        ]
                    )
                , Ui.clipWithEllipsis
                ]
                (Ui.text (User.toStringAlt userId localUser))
            , Ui.el [ Ui.width (Ui.portion (1000 - filled)) ] Ui.none
            ]
        , Ui.el [ Ui.width (Ui.px 40) ] Ui.none
        ]


finalResultsView : LocalUser -> List (Id UserId) -> Element msg
finalResultsView localUser winners =
    Ui.column
        [ Ui.spacing 48, Ui.Font.size 24 ]
        [ Ui.Prose.paragraph
            [ Ui.Font.center ]
            (Ui.text "🐑 And the winner is "
                :: (case winners of
                        [] ->
                            [ Ui.text "...no one?" ]

                        _ ->
                            List.map
                                (\userId ->
                                    Ui.el
                                        [ Ui.width Ui.shrink
                                        , Ui.Font.bold
                                        , Ui.Font.color (userColor userId localUser)
                                        ]
                                        (Ui.text (User.toStringAlt userId localUser))
                                )
                                winners
                                |> List.intersperse (Ui.text ", ")
                   )
                ++ [ Ui.text " 🐑" ]
            )
        , Ui.Prose.paragraph [ Ui.Font.center ] [ Ui.text "Thanks for playing!" ]
        ]


{-| A square for every pair of players, shaded by how often they answered the same thing.
It's turned on its side so that the diagonal runs along the bottom and each player's name
sits at the end of their own row and column.
-}
resultsGridView :
    Bool
    -> LocalUser
    -> ValidatedSetup
    -> Shared
    -> Maybe ( Id UserId, Id UserId )
    -> Element GameMsg
resultsGridView isMobile localUser setup shared gridHovered =
    let
        everyone : List (Id UserId)
        everyone =
            players shared

        overlap : SeqDict ( Id UserId, Id UserId ) Int
        overlap =
            matchingAnswerCounts setup shared

        highestMatchCount : Int
        highestMatchCount =
            SeqDict.values overlap |> List.maximum |> Maybe.withDefault 0
    in
    Ui.row
        [ Ui.spacing 16 ]
        [ Ui.column
            [ Ui.width Ui.shrink
            , Ui.Font.bold
            , Ui.rotate (Ui.radians (pi / 4))
            , Ui.move (Ui.left (List.length everyone * gridCellSize // 2))
            ]
            (List.indexedMap
                (\columnIndex userId ->
                    List.indexedMap
                        (\rowIndex otherUserId ->
                            resultsGridCell
                                localUser
                                gridHovered
                                overlap
                                highestMatchCount
                                { columnIndex = columnIndex, rowIndex = rowIndex }
                                ( userId, otherUserId )
                        )
                        everyone
                        |> Ui.row
                            [ Ui.width Ui.shrink
                            , if columnIndex < List.length everyone - 1 then
                                Ui.onRight (resultsGridLabel localUser gridHovered Tuple.first userId)

                              else
                                Ui.noAttr
                            ]
                )
                everyone
            )
        , if isMobile then
            Ui.none

          else
            case gridHovered |> Maybe.andThen (\pair -> SeqDict.get pair overlap |> Maybe.map (Tuple.pair pair)) of
                Just ( ( userIdA, userIdB ), count ) ->
                    Ui.column
                        [ Ui.spacing 16, Ui.Font.size 16 ]
                        [ Ui.Prose.paragraph
                            []
                            [ Ui.text (User.toStringAlt userIdA localUser)
                            , Ui.text " and "
                            , Ui.text (User.toStringAlt userIdB localUser)
                            , Ui.text " have "
                            , Ui.el [ Ui.width Ui.shrink, Ui.Font.bold ] (Ui.text (String.fromInt count))
                            , Ui.text
                                (if count == 1 then
                                    " matching answer."

                                 else
                                    " matching answers."
                                )
                            ]
                        , if count == highestMatchCount && count > 0 then
                            Ui.Prose.paragraph
                                []
                                [ Ui.text "🐑 This is the highest number of matching answers! 🐑" ]

                          else
                            Ui.none
                        ]

                Nothing ->
                    Ui.Prose.paragraph
                        [ Ui.widthMax 400, Ui.Font.size 16, Ui.Font.color MyUi.font3 ]
                        [ Ui.text "Move your cursor over a grid square to see how many matching answers two players got." ]
        ]


gridCellSize : number
gridCellSize =
    30


resultsGridCell :
    LocalUser
    -> Maybe ( Id UserId, Id UserId )
    -> SeqDict ( Id UserId, Id UserId ) Int
    -> Int
    -> { columnIndex : Int, rowIndex : Int }
    -> ( Id UserId, Id UserId )
    -> Element GameMsg
resultsGridCell localUser gridHovered overlap highestMatchCount { columnIndex, rowIndex } ( userId, otherUserId ) =
    let
        -- Only half of the grid says anything. The other half is the same pairs the other
        -- way around, and the diagonal is everyone against themselves.
        isFilled : Bool
        isFilled =
            columnIndex < rowIndex

        highlight : Int
        highlight =
            case gridHovered of
                Just ( hoveredColumn, hoveredRow ) ->
                    if hoveredRow == otherUserId || hoveredColumn == userId then
                        50

                    else
                        0

                Nothing ->
                    0

        matched : Int
        matched =
            if highestMatchCount <= 0 then
                0

            else
                SeqDict.get ( userId, otherUserId ) overlap
                    |> Maybe.withDefault 0
                    |> (\count -> round (toFloat count / toFloat highestMatchCount * 255))
    in
    Ui.el
        ([ Ui.width (Ui.px gridCellSize)
         , Ui.height (Ui.px gridCellSize)
         , Ui.background
            (if isFilled then
                Ui.rgb highlight matched highlight

             else
                Ui.rgba 0 0 0 0
            )
         , if columnIndex == 0 && rowIndex > 0 then
            Ui.above (resultsGridLabel localUser gridHovered Tuple.second otherUserId |> Ui.el [ Ui.rotate (Ui.turns -0.25) ])

           else
            Ui.noAttr
         ]
            ++ (if isFilled then
                    [ Ui.Events.onMouseEnter (HoveredResultsGrid ( userId, otherUserId ))
                    , Ui.Events.onMouseLeave (ExitedResultsGrid ( userId, otherUserId ))
                    ]

                else
                    []
               )
        )
        Ui.none


{-| A player's name at the end of their row or column. The grid is rotated, so these are
turned back the other way to read straight.
-}
resultsGridLabel :
    LocalUser
    -> Maybe ( Id UserId, Id UserId )
    -> (( Id UserId, Id UserId ) -> Id UserId)
    -> Id UserId
    -> Element msg
resultsGridLabel localUser gridHovered hoveredSide userId =
    Ui.el
        [ Ui.width Ui.shrink
        , Ui.height (Ui.px gridCellSize)
        , Ui.paddingXY 8 0
        , Ui.contentCenterY
        , MyUi.noPointerEvents
        , Ui.Font.color (userColor userId localUser)
        , if Maybe.map hoveredSide gridHovered == Just userId then
            Ui.background (Ui.rgba 255 255 255 0.1)

          else
            Ui.noAttr
        ]
        (Ui.text (User.toStringAlt userId localUser))


{-| How many questions each pair of players landed in the same group on. Both orderings of
a pair are counted so that either half of the grid can look one up.
-}
matchingAnswerCounts : ValidatedSetup -> Shared -> SeqDict ( Id UserId, Id UserId ) Int
matchingAnswerCounts setup shared =
    let
        everyone : List (Id UserId)
        everyone =
            players shared
    in
    List.range 0 (List.Nonempty.length setup.questions - 1)
        |> List.concatMap
            (\index ->
                let
                    questionId : Id QuestionId
                    questionId =
                        Id.fromInt index

                    groupOf : Id UserId -> Maybe String
                    groupOf userId =
                        case answerFor userId questionId shared of
                            Just _ ->
                                SeqDict.get ( userId, questionId ) shared.groups |> Maybe.withDefault "" |> Just

                            Nothing ->
                                Nothing
                in
                List.concatMap
                    (\userId ->
                        List.filterMap
                            (\otherUserId ->
                                if userId == otherUserId then
                                    Nothing

                                else
                                    case ( groupOf userId, groupOf otherUserId ) of
                                        ( Just group, Just otherGroup ) ->
                                            Just ( ( userId, otherUserId ), group == otherGroup )

                                        _ ->
                                            Nothing
                            )
                            everyone
                    )
                    everyone
            )
        |> List.foldl
            (\( pair, matched ) counts ->
                SeqDict.update
                    pair
                    (\maybe ->
                        Maybe.withDefault 0 maybe
                            + (if matched then
                                1

                               else
                                0
                              )
                            |> Just
                    )
                    counts
            )
            SeqDict.empty


fileUploadPreviewSize : number
fileUploadPreviewSize =
    150


fileUploadPreview :
    (Id FileId -> msg)
    -> (Id FileId -> msg)
    -> ({ fileId : Id FileId, removeSpoiler : Bool } -> msg)
    -> Maybe (Nonempty (RichText userId))
    -> NonemptyDict (Id FileId) FileStatus
    -> List (Element msg)
fileUploadPreview onPressDelete onPressInfo onPressSpoiler richText filesToUpload2 =
    let
        isSpoilered : SeqDict (Id FileId) Bool
        isSpoilered =
            case richText of
                Just richText2 ->
                    RichText.attachments richText2
                        |> List.map (\a -> ( a.attachmentId, a.isSpoilered ))
                        |> SeqDict.fromList

                Nothing ->
                    SeqDict.empty
    in
    List.map
        (\( fileStatusId, fileStatus ) ->
            let
                isSpoilered2 : Bool
                isSpoilered2 =
                    SeqDict.get fileStatusId isSpoilered |> Maybe.withDefault False
            in
            Ui.el
                [ Ui.width (Ui.px fileUploadPreviewSize)
                , Ui.height (Ui.px fileUploadPreviewSize)
                , Ui.background MyUi.background1
                , Ui.borderColor (Ui.rgb 150 150 160)
                , Ui.border 1
                , Ui.rounded 8
                , MyUi.elButton
                    (Dom.id ("fileStatus_delete_" ++ Id.toString fileStatusId))
                    (onPressDelete fileStatusId)
                    [ Ui.width (Ui.px 42)
                    , Ui.height (Ui.px 42)
                    , Ui.rounded 16
                    , Ui.move { x = -3, y = -3, z = 0 }
                    , MyUi.hoverText "Remove file"
                    ]
                    (Ui.el
                        [ Ui.width (Ui.px 34)
                        , Ui.height (Ui.px 34)
                        , Ui.rounded 16
                        , Ui.contentCenterX
                        , Ui.contentCenterY
                        , Ui.background MyUi.deleteButtonBackground
                        , Ui.border 1
                        , Ui.borderColor MyUi.deleteButtonBorder
                        ]
                        (Ui.html Icons.delete)
                    )
                    |> Ui.inFront
                , MyUi.elButton
                    (Dom.id ("fileStatus_spoiler_" ++ Id.toString fileStatusId))
                    (onPressSpoiler { fileId = fileStatusId, removeSpoiler = isSpoilered2 })
                    [ Ui.width (Ui.px 42)
                    , Ui.height (Ui.px 42)
                    , Ui.rounded 16
                    , Ui.move { x = -3, y = 40, z = 0 }
                    , MyUi.hoverText
                        (if isSpoilered2 then
                            "Remove spoiler"

                         else
                            "Mark as spoiler"
                        )
                    ]
                    (Ui.el
                        [ Ui.width (Ui.px 34)
                        , Ui.height (Ui.px 34)
                        , Ui.rounded 16
                        , Ui.contentCenterX
                        , Ui.contentCenterY
                        , Ui.background MyUi.buttonBackground
                        ]
                        (Ui.html
                            (if isSpoilered2 then
                                Icons.closedEye

                             else
                                Icons.openEye
                            )
                        )
                    )
                    |> Ui.inFront
                , case fileStatus of
                    FileStatus.FileUploaded fileData ->
                        case fileData.metadata of
                            Just (FileMetadata_Image imageMetadata) ->
                                if FileStatus.imageHasMetadata imageMetadata then
                                    fileUploadInfoButton onPressInfo fileStatusId imageMetadata

                                else
                                    Ui.noAttr

                            Just (FileMetadata_Video videoMetadata) ->
                                if FileStatus.videoHasMetadata videoMetadata then
                                    fileUploadInfoButton onPressInfo fileStatusId videoMetadata

                                else
                                    Ui.noAttr

                            Nothing ->
                                Ui.noAttr

                    FileStatus.FileUploading _ _ _ ->
                        Ui.noAttr

                    FileStatus.FileError _ _ _ _ ->
                        Ui.noAttr
                , Ui.el
                    [ Ui.alignBottom
                    , Ui.padding 4
                    , Ui.Font.bold
                    , Ui.Shadow.font
                        { offset = ( 0, 0 )
                        , blur = 3
                        , color = MyUi.black
                        }
                    ]
                    (Ui.text ("[!" ++ Id.toString fileStatusId ++ "]"))
                    |> Ui.inFront
                , case fileStatus of
                    FileStatus.FileUploading _ fileSize _ ->
                        FileStatus.progressToString fileSize
                            |> Ui.text
                            |> Ui.el
                                [ Ui.alignRight
                                , Ui.Font.size 14
                                , Ui.paddingRight 8
                                , Ui.Shadow.font
                                    { offset = ( 0, 0 )
                                    , blur = 3
                                    , color = MyUi.black
                                    }
                                ]
                            |> Ui.inFront

                    FileStatus.FileUploaded _ ->
                        Ui.noAttr

                    FileStatus.FileError _ _ _ _ ->
                        Ui.noAttr
                ]
                (case fileStatus of
                    FileStatus.FileUploading _ _ _ ->
                        Ui.none

                    FileStatus.FileUploaded fileData ->
                        case FileStatus.contentTypeType fileData.contentType of
                            FileStatus.Image ->
                                Html.img
                                    [ Html.Attributes.src
                                        (case fileData.metadata of
                                            Just (FileMetadata_Image metadata) ->
                                                FileStatus.thumbnailUrl metadata.imageSize fileData.contentType fileData.fileHash

                                            Just (FileMetadata_Video _) ->
                                                FileStatus.fileUrl fileData.contentType fileData.fileHash

                                            Nothing ->
                                                FileStatus.fileUrl fileData.contentType fileData.fileHash
                                        )
                                    , Html.Attributes.style "object-fit" "cover"
                                    , Html.Attributes.width (fileUploadPreviewSize - 2)
                                    , Html.Attributes.height (fileUploadPreviewSize - 2)
                                    , Html.Attributes.style "display" "flex"
                                    , Html.Attributes.style "align-self" "center"
                                    , Html.Attributes.style "border-radius" "8px"
                                    ]
                                    []
                                    |> Ui.html

                            FileStatus.Text ->
                                Ui.el
                                    [ Ui.width (Ui.px 42)
                                    , Ui.centerX
                                    , Ui.centerY
                                    , Ui.Font.color MyUi.font3
                                    ]
                                    (Ui.html Icons.document)

                            FileStatus.Video ->
                                Ui.el
                                    [ Ui.centerX
                                    , Ui.centerY
                                    , Ui.Font.color MyUi.font3
                                    , Ui.move { x = 6, y = 0, z = 0 }
                                    ]
                                    (Ui.html (Icons.camera 42))

                            FileStatus.Audio ->
                                Ui.el
                                    [ Ui.width (Ui.px 42)
                                    , Ui.centerX
                                    , Ui.centerY
                                    , Ui.Font.color MyUi.font3
                                    ]
                                    (Ui.html Icons.volume)

                            _ ->
                                Ui.el
                                    [ Ui.Font.bold
                                    , Ui.Font.letterSpacing -1
                                    , Ui.Font.lineHeight 1.1
                                    , Ui.centerX
                                    , Ui.centerY
                                    , MyUi.prewrap
                                    , Ui.Font.color MyUi.font3
                                    ]
                                    (Ui.text "0110\n0001")

                    FileStatus.FileError _ _ _ _ ->
                        Ui.el
                            [ Ui.centerX
                            , Ui.centerY
                            , Ui.width Ui.shrink
                            ]
                            (Ui.html Icons.x)
                )
        )
        (NonemptyDict.toList filesToUpload2)


fileUploadInfoButton : (Id FileId -> msg) -> Id FileId -> { b | gpsLocation : Maybe FileStatus.Location } -> Ui.Attribute msg
fileUploadInfoButton onPressInfo fileStatusId metadata =
    MyUi.elButton
        (Dom.id ("fileStatus_info_" ++ Id.toString fileStatusId))
        (onPressInfo fileStatusId)
        [ Ui.width (Ui.px 42)
        , Ui.height (Ui.px 42)
        , Ui.rounded 16
        , Ui.move { x = -3, y = 77, z = 0 }
        , MyUi.hoverText "Image info"
        ]
        (Ui.el
            [ Ui.width (Ui.px 34)
            , Ui.height (Ui.px 34)
            , Ui.rounded 16
            , Ui.contentCenterX
            , Ui.contentCenterY
            , Ui.background MyUi.buttonBackground
            ]
            (case metadata.gpsLocation of
                Just _ ->
                    Ui.html Icons.map

                Nothing ->
                    Ui.html Icons.info
            )
        )
        |> Ui.inFront
