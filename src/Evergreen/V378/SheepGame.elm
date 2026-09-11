module Evergreen.V378.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V378.Emoji
import Evergreen.V378.FileStatus
import Evergreen.V378.Id
import Evergreen.V378.IdArray
import Evergreen.V378.MessageInput
import Evergreen.V378.MessageView
import Evergreen.V378.NonemptySet
import Evergreen.V378.RichText
import Evergreen.V378.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)
    | NotesReaction (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) Evergreen.V378.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)
        { fileId : Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) String
    | TypedNotes (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) Evergreen.V378.MessageInput.Msg
    | GotNotesFiles (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)
        { fileId : Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Evergreen.V378.Id.Id Evergreen.V378.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Evergreen.V378.Id.Id Evergreen.V378.Id.UserId )
    | UserScrolledResults Evergreen.V378.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V378.MessageView.MessageViewMsg
    | PressedImage Evergreen.V378.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) Evergreen.V378.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V378.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)
        { fileId : Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)
    | AnswerInput (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)
    | NotesInput (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V378.Emoji.EmojiOrCustomEmoji (Evergreen.V378.NonemptySet.NonemptySet (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V378.RichText.RichText (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) String
    | ChangedNotes (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V378.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.FileStatus.FileId) Evergreen.V378.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Evergreen.V378.Id.Id Evergreen.V378.Id.UserId )
    , scrollPosition : Evergreen.V378.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
