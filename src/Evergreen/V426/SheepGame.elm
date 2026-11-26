module Evergreen.V426.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V426.Emoji
import Evergreen.V426.FileStatus
import Evergreen.V426.Id
import Evergreen.V426.IdArray
import Evergreen.V426.MessageInput
import Evergreen.V426.MessageView
import Evergreen.V426.NonemptySet
import Evergreen.V426.RichText
import Evergreen.V426.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
    | NotesReaction (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) Evergreen.V426.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
        { fileId : Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) String
    | TypedNotes (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) Evergreen.V426.MessageInput.Msg
    | GotNotesFiles (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
        { fileId : Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
    | ExitedQuestion (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.Id.Id Evergreen.V426.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.Id.Id Evergreen.V426.Id.UserId )
    | UserScrolledResults Evergreen.V426.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V426.MessageView.MessageViewMsg
    | PressedImage Evergreen.V426.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) Evergreen.V426.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V426.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
        { fileId : Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
    | AnswerInput (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
    | NotesInput (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V426.Emoji.EmojiOrCustomEmoji (Evergreen.V426.NonemptySet.NonemptySet (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V426.RichText.RichText (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) String
    | ChangedNotes (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V426.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.Id.Id Evergreen.V426.Id.UserId )
    , scrollPosition : Evergreen.V426.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
