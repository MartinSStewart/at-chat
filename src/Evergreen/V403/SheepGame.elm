module Evergreen.V403.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V403.Emoji
import Evergreen.V403.FileStatus
import Evergreen.V403.Id
import Evergreen.V403.IdArray
import Evergreen.V403.MessageInput
import Evergreen.V403.MessageView
import Evergreen.V403.NonemptySet
import Evergreen.V403.RichText
import Evergreen.V403.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    | NotesReaction (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) Evergreen.V403.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
        { fileId : Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) String
    | TypedNotes (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) Evergreen.V403.MessageInput.Msg
    | GotNotesFiles (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
        { fileId : Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    | ExitedQuestion (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Evergreen.V403.Id.Id Evergreen.V403.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Evergreen.V403.Id.Id Evergreen.V403.Id.UserId )
    | UserScrolledResults Evergreen.V403.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V403.MessageView.MessageViewMsg
    | PressedImage Evergreen.V403.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) Evergreen.V403.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V403.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
        { fileId : Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    | AnswerInput (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    | NotesInput (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V403.Emoji.EmojiOrCustomEmoji (Evergreen.V403.NonemptySet.NonemptySet (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V403.RichText.RichText (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) String
    | ChangedNotes (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V403.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Evergreen.V403.Id.Id Evergreen.V403.Id.UserId )
    , scrollPosition : Evergreen.V403.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
