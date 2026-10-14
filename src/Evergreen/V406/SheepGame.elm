module Evergreen.V406.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V406.Emoji
import Evergreen.V406.FileStatus
import Evergreen.V406.Id
import Evergreen.V406.IdArray
import Evergreen.V406.MessageInput
import Evergreen.V406.MessageView
import Evergreen.V406.NonemptySet
import Evergreen.V406.RichText
import Evergreen.V406.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
    | NotesReaction (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) Evergreen.V406.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
        { fileId : Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) String
    | TypedNotes (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) Evergreen.V406.MessageInput.Msg
    | GotNotesFiles (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
        { fileId : Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
    | ExitedQuestion (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Evergreen.V406.Id.Id Evergreen.V406.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Evergreen.V406.Id.Id Evergreen.V406.Id.UserId )
    | UserScrolledResults Evergreen.V406.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V406.MessageView.MessageViewMsg
    | PressedImage Evergreen.V406.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) Evergreen.V406.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V406.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
        { fileId : Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
    | AnswerInput (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
    | NotesInput (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V406.Emoji.EmojiOrCustomEmoji (Evergreen.V406.NonemptySet.NonemptySet (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V406.RichText.RichText (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) String
    | ChangedNotes (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V406.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Evergreen.V406.Id.Id Evergreen.V406.Id.UserId )
    , scrollPosition : Evergreen.V406.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
