module Evergreen.V413.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V413.Emoji
import Evergreen.V413.FileStatus
import Evergreen.V413.Id
import Evergreen.V413.IdArray
import Evergreen.V413.MessageInput
import Evergreen.V413.MessageView
import Evergreen.V413.NonemptySet
import Evergreen.V413.RichText
import Evergreen.V413.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
    | NotesReaction (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) Evergreen.V413.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
        { fileId : Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) String
    | TypedNotes (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) Evergreen.V413.MessageInput.Msg
    | GotNotesFiles (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
        { fileId : Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
    | ExitedQuestion (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Evergreen.V413.Id.Id Evergreen.V413.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Evergreen.V413.Id.Id Evergreen.V413.Id.UserId )
    | UserScrolledResults Evergreen.V413.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V413.MessageView.MessageViewMsg
    | PressedImage Evergreen.V413.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) Evergreen.V413.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V413.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
        { fileId : Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
    | AnswerInput (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
    | NotesInput (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V413.Emoji.EmojiOrCustomEmoji (Evergreen.V413.NonemptySet.NonemptySet (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V413.RichText.RichText (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) String
    | ChangedNotes (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V413.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId) Evergreen.V413.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Evergreen.V413.Id.Id Evergreen.V413.Id.UserId )
    , scrollPosition : Evergreen.V413.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
