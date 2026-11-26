module Evergreen.V425.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V425.Emoji
import Evergreen.V425.FileStatus
import Evergreen.V425.Id
import Evergreen.V425.IdArray
import Evergreen.V425.MessageInput
import Evergreen.V425.MessageView
import Evergreen.V425.NonemptySet
import Evergreen.V425.RichText
import Evergreen.V425.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    | NotesReaction (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) Evergreen.V425.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
        { fileId : Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) String
    | TypedNotes (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) Evergreen.V425.MessageInput.Msg
    | GotNotesFiles (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
        { fileId : Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    | ExitedQuestion (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Evergreen.V425.Id.Id Evergreen.V425.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Evergreen.V425.Id.Id Evergreen.V425.Id.UserId )
    | UserScrolledResults Evergreen.V425.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V425.MessageView.MessageViewMsg
    | PressedImage Evergreen.V425.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) Evergreen.V425.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V425.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
        { fileId : Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    | AnswerInput (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    | NotesInput (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V425.Emoji.EmojiOrCustomEmoji (Evergreen.V425.NonemptySet.NonemptySet (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) String
    | ChangedNotes (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V425.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Evergreen.V425.Id.Id Evergreen.V425.Id.UserId )
    , scrollPosition : Evergreen.V425.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
