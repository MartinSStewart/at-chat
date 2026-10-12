module Evergreen.V405.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V405.Emoji
import Evergreen.V405.FileStatus
import Evergreen.V405.Id
import Evergreen.V405.IdArray
import Evergreen.V405.MessageInput
import Evergreen.V405.MessageView
import Evergreen.V405.NonemptySet
import Evergreen.V405.RichText
import Evergreen.V405.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    | NotesReaction (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) Evergreen.V405.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
        { fileId : Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) String
    | TypedNotes (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) Evergreen.V405.MessageInput.Msg
    | GotNotesFiles (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
        { fileId : Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    | ExitedQuestion (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Evergreen.V405.Id.Id Evergreen.V405.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Evergreen.V405.Id.Id Evergreen.V405.Id.UserId )
    | UserScrolledResults Evergreen.V405.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V405.MessageView.MessageViewMsg
    | PressedImage Evergreen.V405.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) Evergreen.V405.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V405.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
        { fileId : Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    | AnswerInput (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    | NotesInput (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V405.Emoji.EmojiOrCustomEmoji (Evergreen.V405.NonemptySet.NonemptySet (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) String
    | ChangedNotes (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V405.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Evergreen.V405.Id.Id Evergreen.V405.Id.UserId )
    , scrollPosition : Evergreen.V405.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
