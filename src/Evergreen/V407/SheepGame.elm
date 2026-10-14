module Evergreen.V407.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V407.Emoji
import Evergreen.V407.FileStatus
import Evergreen.V407.Id
import Evergreen.V407.IdArray
import Evergreen.V407.MessageInput
import Evergreen.V407.MessageView
import Evergreen.V407.NonemptySet
import Evergreen.V407.RichText
import Evergreen.V407.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    | NotesReaction (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) Evergreen.V407.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
        { fileId : Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) String
    | TypedNotes (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) Evergreen.V407.MessageInput.Msg
    | GotNotesFiles (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
        { fileId : Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    | ExitedQuestion (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Evergreen.V407.Id.Id Evergreen.V407.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Evergreen.V407.Id.Id Evergreen.V407.Id.UserId )
    | UserScrolledResults Evergreen.V407.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V407.MessageView.MessageViewMsg
    | PressedImage Evergreen.V407.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) Evergreen.V407.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V407.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
        { fileId : Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    | AnswerInput (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    | NotesInput (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V407.Emoji.EmojiOrCustomEmoji (Evergreen.V407.NonemptySet.NonemptySet (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) String
    | ChangedNotes (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V407.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Evergreen.V407.Id.Id Evergreen.V407.Id.UserId )
    , scrollPosition : Evergreen.V407.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
