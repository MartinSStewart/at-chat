module Evergreen.V408.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V408.Emoji
import Evergreen.V408.FileStatus
import Evergreen.V408.Id
import Evergreen.V408.IdArray
import Evergreen.V408.MessageInput
import Evergreen.V408.MessageView
import Evergreen.V408.NonemptySet
import Evergreen.V408.RichText
import Evergreen.V408.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
    | NotesReaction (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) Evergreen.V408.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
        { fileId : Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) String
    | TypedNotes (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) Evergreen.V408.MessageInput.Msg
    | GotNotesFiles (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
        { fileId : Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
    | ExitedQuestion (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Evergreen.V408.Id.Id Evergreen.V408.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Evergreen.V408.Id.Id Evergreen.V408.Id.UserId )
    | UserScrolledResults Evergreen.V408.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V408.MessageView.MessageViewMsg
    | PressedImage Evergreen.V408.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) Evergreen.V408.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V408.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
        { fileId : Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
    | AnswerInput (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
    | NotesInput (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V408.Emoji.EmojiOrCustomEmoji (Evergreen.V408.NonemptySet.NonemptySet (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V408.RichText.RichText (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) String
    | ChangedNotes (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V408.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId) Evergreen.V408.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Evergreen.V408.Id.Id Evergreen.V408.Id.UserId )
    , scrollPosition : Evergreen.V408.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V408.Id.Id Evergreen.V408.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
