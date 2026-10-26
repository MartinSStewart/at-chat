module Evergreen.V412.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V412.Emoji
import Evergreen.V412.FileStatus
import Evergreen.V412.Id
import Evergreen.V412.IdArray
import Evergreen.V412.MessageInput
import Evergreen.V412.MessageView
import Evergreen.V412.NonemptySet
import Evergreen.V412.RichText
import Evergreen.V412.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    | NotesReaction (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) Evergreen.V412.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
        { fileId : Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) String
    | TypedNotes (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) Evergreen.V412.MessageInput.Msg
    | GotNotesFiles (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
        { fileId : Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    | ExitedQuestion (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Evergreen.V412.Id.Id Evergreen.V412.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Evergreen.V412.Id.Id Evergreen.V412.Id.UserId )
    | UserScrolledResults Evergreen.V412.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V412.MessageView.MessageViewMsg
    | PressedImage Evergreen.V412.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) Evergreen.V412.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V412.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
        { fileId : Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    | AnswerInput (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    | NotesInput (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V412.Emoji.EmojiOrCustomEmoji (Evergreen.V412.NonemptySet.NonemptySet (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) String
    | ChangedNotes (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V412.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V412.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Evergreen.V412.Id.Id Evergreen.V412.Id.UserId )
    , scrollPosition : Evergreen.V412.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
