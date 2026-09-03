module Evergreen.V367.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V367.Emoji
import Evergreen.V367.FileStatus
import Evergreen.V367.Id
import Evergreen.V367.IdArray
import Evergreen.V367.MessageInput
import Evergreen.V367.MessageView
import Evergreen.V367.NonemptySet
import Evergreen.V367.RichText
import Evergreen.V367.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)
    | NotesReaction (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) Evergreen.V367.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)
        { fileId : Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) String
    | TypedNotes (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) Evergreen.V367.MessageInput.Msg
    | GotNotesFiles (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)
        { fileId : Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V367.Id.Id Evergreen.V367.Id.UserId, Evergreen.V367.Id.Id Evergreen.V367.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V367.Id.Id Evergreen.V367.Id.UserId, Evergreen.V367.Id.Id Evergreen.V367.Id.UserId )
    | UserScrolledResults Evergreen.V367.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V367.MessageView.MessageViewMsg
    | PressedImage Evergreen.V367.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) Evergreen.V367.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V367.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)
        { fileId : Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)
    | AnswerInput (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)
    | NotesInput (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V367.Emoji.EmojiOrCustomEmoji (Evergreen.V367.NonemptySet.NonemptySet (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V367.RichText.RichText (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V367.Id.Id Evergreen.V367.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) String
    | ChangedNotes (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V367.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V367.Id.Id Evergreen.V367.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V367.Id.Id Evergreen.V367.Id.UserId, Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V367.Id.Id Evergreen.V367.Id.UserId, Evergreen.V367.Id.Id Evergreen.V367.Id.UserId )
    , scrollPosition : Evergreen.V367.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
