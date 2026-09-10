module Evergreen.V376.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V376.Emoji
import Evergreen.V376.FileStatus
import Evergreen.V376.Id
import Evergreen.V376.IdArray
import Evergreen.V376.MessageInput
import Evergreen.V376.MessageView
import Evergreen.V376.NonemptySet
import Evergreen.V376.RichText
import Evergreen.V376.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)
    | NotesReaction (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) Evergreen.V376.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)
        { fileId : Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) String
    | TypedNotes (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) Evergreen.V376.MessageInput.Msg
    | GotNotesFiles (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)
        { fileId : Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Evergreen.V376.Id.Id Evergreen.V376.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Evergreen.V376.Id.Id Evergreen.V376.Id.UserId )
    | UserScrolledResults Evergreen.V376.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V376.MessageView.MessageViewMsg
    | PressedImage Evergreen.V376.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) Evergreen.V376.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V376.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)
        { fileId : Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)
    | AnswerInput (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)
    | NotesInput (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V376.Emoji.EmojiOrCustomEmoji (Evergreen.V376.NonemptySet.NonemptySet (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V376.RichText.RichText (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) String
    | ChangedNotes (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V376.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Evergreen.V376.Id.Id Evergreen.V376.Id.UserId )
    , scrollPosition : Evergreen.V376.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
