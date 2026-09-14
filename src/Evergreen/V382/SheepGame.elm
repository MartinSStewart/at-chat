module Evergreen.V382.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V382.Emoji
import Evergreen.V382.FileStatus
import Evergreen.V382.Id
import Evergreen.V382.IdArray
import Evergreen.V382.MessageInput
import Evergreen.V382.MessageView
import Evergreen.V382.NonemptySet
import Evergreen.V382.RichText
import Evergreen.V382.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)
    | NotesReaction (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) Evergreen.V382.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)
        { fileId : Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) String
    | TypedNotes (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) Evergreen.V382.MessageInput.Msg
    | GotNotesFiles (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)
        { fileId : Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Evergreen.V382.Id.Id Evergreen.V382.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Evergreen.V382.Id.Id Evergreen.V382.Id.UserId )
    | UserScrolledResults Evergreen.V382.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V382.MessageView.MessageViewMsg
    | PressedImage Evergreen.V382.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) Evergreen.V382.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V382.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)
        { fileId : Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)
    | AnswerInput (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)
    | NotesInput (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V382.Emoji.EmojiOrCustomEmoji (Evergreen.V382.NonemptySet.NonemptySet (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V382.RichText.RichText (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) String
    | ChangedNotes (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V382.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V382.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Evergreen.V382.Id.Id Evergreen.V382.Id.UserId )
    , scrollPosition : Evergreen.V382.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
