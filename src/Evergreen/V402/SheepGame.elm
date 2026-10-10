module Evergreen.V402.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V402.Emoji
import Evergreen.V402.FileStatus
import Evergreen.V402.Id
import Evergreen.V402.IdArray
import Evergreen.V402.MessageInput
import Evergreen.V402.MessageView
import Evergreen.V402.NonemptySet
import Evergreen.V402.RichText
import Evergreen.V402.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
    | NotesReaction (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) Evergreen.V402.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
        { fileId : Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) String
    | TypedNotes (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) Evergreen.V402.MessageInput.Msg
    | GotNotesFiles (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
        { fileId : Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
    | ExitedQuestion (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Evergreen.V402.Id.Id Evergreen.V402.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Evergreen.V402.Id.Id Evergreen.V402.Id.UserId )
    | UserScrolledResults Evergreen.V402.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V402.MessageView.MessageViewMsg
    | PressedImage Evergreen.V402.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) Evergreen.V402.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V402.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
        { fileId : Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
    | AnswerInput (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
    | NotesInput (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V402.Emoji.EmojiOrCustomEmoji (Evergreen.V402.NonemptySet.NonemptySet (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V402.RichText.RichText (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) String
    | ChangedNotes (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V402.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Evergreen.V402.Id.Id Evergreen.V402.Id.UserId )
    , scrollPosition : Evergreen.V402.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
