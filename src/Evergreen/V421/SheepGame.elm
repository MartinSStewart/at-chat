module Evergreen.V421.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V421.Emoji
import Evergreen.V421.FileStatus
import Evergreen.V421.Id
import Evergreen.V421.IdArray
import Evergreen.V421.MessageInput
import Evergreen.V421.MessageView
import Evergreen.V421.NonemptySet
import Evergreen.V421.RichText
import Evergreen.V421.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
    | NotesReaction (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) Evergreen.V421.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
        { fileId : Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) String
    | TypedNotes (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) Evergreen.V421.MessageInput.Msg
    | GotNotesFiles (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
        { fileId : Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
    | ExitedQuestion (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Evergreen.V421.Id.Id Evergreen.V421.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Evergreen.V421.Id.Id Evergreen.V421.Id.UserId )
    | UserScrolledResults Evergreen.V421.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V421.MessageView.MessageViewMsg
    | PressedImage Evergreen.V421.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) Evergreen.V421.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V421.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
        { fileId : Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
    | AnswerInput (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
    | NotesInput (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V421.Emoji.EmojiOrCustomEmoji (Evergreen.V421.NonemptySet.NonemptySet (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V421.RichText.RichText (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) String
    | ChangedNotes (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V421.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.FileStatus.FileId) Evergreen.V421.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Evergreen.V421.Id.Id Evergreen.V421.Id.UserId )
    , scrollPosition : Evergreen.V421.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
