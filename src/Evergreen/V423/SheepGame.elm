module Evergreen.V423.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V423.Emoji
import Evergreen.V423.FileStatus
import Evergreen.V423.Id
import Evergreen.V423.IdArray
import Evergreen.V423.MessageInput
import Evergreen.V423.MessageView
import Evergreen.V423.NonemptySet
import Evergreen.V423.RichText
import Evergreen.V423.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
    | NotesReaction (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) Evergreen.V423.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
        { fileId : Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) String
    | TypedNotes (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) Evergreen.V423.MessageInput.Msg
    | GotNotesFiles (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
        { fileId : Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
    | ExitedQuestion (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Evergreen.V423.Id.Id Evergreen.V423.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Evergreen.V423.Id.Id Evergreen.V423.Id.UserId )
    | UserScrolledResults Evergreen.V423.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V423.MessageView.MessageViewMsg
    | PressedImage Evergreen.V423.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) Evergreen.V423.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V423.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
        { fileId : Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
    | AnswerInput (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
    | NotesInput (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V423.Emoji.EmojiOrCustomEmoji (Evergreen.V423.NonemptySet.NonemptySet (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V423.RichText.RichText (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) String
    | ChangedNotes (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V423.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId) Evergreen.V423.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Evergreen.V423.Id.Id Evergreen.V423.Id.UserId )
    , scrollPosition : Evergreen.V423.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
