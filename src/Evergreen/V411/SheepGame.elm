module Evergreen.V411.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V411.Emoji
import Evergreen.V411.FileStatus
import Evergreen.V411.Id
import Evergreen.V411.IdArray
import Evergreen.V411.MessageInput
import Evergreen.V411.MessageView
import Evergreen.V411.NonemptySet
import Evergreen.V411.RichText
import Evergreen.V411.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    | NotesReaction (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) Evergreen.V411.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V411.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
        { fileId : Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) String
    | TypedNotes (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) Evergreen.V411.MessageInput.Msg
    | GotNotesFiles (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V411.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
        { fileId : Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    | ExitedQuestion (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, Evergreen.V411.Id.Id Evergreen.V411.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, Evergreen.V411.Id.Id Evergreen.V411.Id.UserId )
    | UserScrolledResults Evergreen.V411.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V411.MessageView.MessageViewMsg
    | PressedImage Evergreen.V411.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) Evergreen.V411.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V411.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
        { fileId : Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    | AnswerInput (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    | NotesInput (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V411.Emoji.EmojiOrCustomEmoji (Evergreen.V411.NonemptySet.NonemptySet (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V411.RichText.RichText (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId) Evergreen.V411.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V411.Id.Id Evergreen.V411.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) String
    | ChangedNotes (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V411.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V411.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V411.Id.Id Evergreen.V411.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId) Evergreen.V411.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, Evergreen.V411.Id.Id Evergreen.V411.Id.UserId )
    , scrollPosition : Evergreen.V411.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
