module Evergreen.V400.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V400.Emoji
import Evergreen.V400.FileStatus
import Evergreen.V400.Id
import Evergreen.V400.IdArray
import Evergreen.V400.MessageInput
import Evergreen.V400.MessageView
import Evergreen.V400.NonemptySet
import Evergreen.V400.RichText
import Evergreen.V400.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
    | NotesReaction (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) Evergreen.V400.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V400.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
        { fileId : Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) String
    | TypedNotes (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) Evergreen.V400.MessageInput.Msg
    | GotNotesFiles (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V400.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
        { fileId : Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
    | ExitedQuestion (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V400.Id.Id Evergreen.V400.Id.UserId, Evergreen.V400.Id.Id Evergreen.V400.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V400.Id.Id Evergreen.V400.Id.UserId, Evergreen.V400.Id.Id Evergreen.V400.Id.UserId )
    | UserScrolledResults Evergreen.V400.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V400.MessageView.MessageViewMsg
    | PressedImage Evergreen.V400.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) Evergreen.V400.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V400.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
        { fileId : Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
    | AnswerInput (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
    | NotesInput (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V400.Emoji.EmojiOrCustomEmoji (Evergreen.V400.NonemptySet.NonemptySet (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V400.RichText.RichText (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId) Evergreen.V400.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) String
    | ChangedNotes (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V400.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V400.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V400.Id.Id Evergreen.V400.Id.UserId, Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId) Evergreen.V400.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V400.Id.Id Evergreen.V400.Id.UserId, Evergreen.V400.Id.Id Evergreen.V400.Id.UserId )
    , scrollPosition : Evergreen.V400.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V400.Id.Id Evergreen.V400.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
