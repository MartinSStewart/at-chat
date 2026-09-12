module Evergreen.V381.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V381.Emoji
import Evergreen.V381.FileStatus
import Evergreen.V381.Id
import Evergreen.V381.IdArray
import Evergreen.V381.MessageInput
import Evergreen.V381.MessageView
import Evergreen.V381.NonemptySet
import Evergreen.V381.RichText
import Evergreen.V381.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)
    | NotesReaction (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) Evergreen.V381.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)
        { fileId : Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) String
    | TypedNotes (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) Evergreen.V381.MessageInput.Msg
    | GotNotesFiles (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)
        { fileId : Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Evergreen.V381.Id.Id Evergreen.V381.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Evergreen.V381.Id.Id Evergreen.V381.Id.UserId )
    | UserScrolledResults Evergreen.V381.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V381.MessageView.MessageViewMsg
    | PressedImage Evergreen.V381.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) Evergreen.V381.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V381.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)
        { fileId : Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)
    | AnswerInput (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)
    | NotesInput (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V381.Emoji.EmojiOrCustomEmoji (Evergreen.V381.NonemptySet.NonemptySet (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V381.RichText.RichText (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) String
    | ChangedNotes (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V381.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId) Evergreen.V381.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Evergreen.V381.Id.Id Evergreen.V381.Id.UserId )
    , scrollPosition : Evergreen.V381.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
