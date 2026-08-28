module Evergreen.V364.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V364.Emoji
import Evergreen.V364.FileStatus
import Evergreen.V364.Id
import Evergreen.V364.IdArray
import Evergreen.V364.MessageInput
import Evergreen.V364.MessageView
import Evergreen.V364.NonemptySet
import Evergreen.V364.RichText
import Evergreen.V364.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)
    | NotesReaction (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) Evergreen.V364.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)
        { fileId : Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) String
    | TypedNotes (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) Evergreen.V364.MessageInput.Msg
    | GotNotesFiles (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)
        { fileId : Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V364.Id.Id Evergreen.V364.Id.UserId, Evergreen.V364.Id.Id Evergreen.V364.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V364.Id.Id Evergreen.V364.Id.UserId, Evergreen.V364.Id.Id Evergreen.V364.Id.UserId )
    | UserScrolledResults Evergreen.V364.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V364.MessageView.MessageViewMsg
    | PressedImage Evergreen.V364.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) Evergreen.V364.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V364.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)
        { fileId : Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)
    | AnswerInput (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)
    | NotesInput (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V364.Emoji.EmojiOrCustomEmoji (Evergreen.V364.NonemptySet.NonemptySet (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V364.RichText.RichText (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) String
    | ChangedNotes (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V364.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V364.Id.Id Evergreen.V364.Id.UserId, Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V364.Id.Id Evergreen.V364.Id.UserId, Evergreen.V364.Id.Id Evergreen.V364.Id.UserId )
    , scrollPosition : Evergreen.V364.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
