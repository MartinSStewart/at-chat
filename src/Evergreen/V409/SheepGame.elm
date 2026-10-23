module Evergreen.V409.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V409.Emoji
import Evergreen.V409.FileStatus
import Evergreen.V409.Id
import Evergreen.V409.IdArray
import Evergreen.V409.MessageInput
import Evergreen.V409.MessageView
import Evergreen.V409.NonemptySet
import Evergreen.V409.RichText
import Evergreen.V409.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    | NotesReaction (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) Evergreen.V409.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
        { fileId : Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) String
    | TypedNotes (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) Evergreen.V409.MessageInput.Msg
    | GotNotesFiles (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
        { fileId : Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    | ExitedQuestion (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Evergreen.V409.Id.Id Evergreen.V409.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Evergreen.V409.Id.Id Evergreen.V409.Id.UserId )
    | UserScrolledResults Evergreen.V409.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V409.MessageView.MessageViewMsg
    | PressedImage Evergreen.V409.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) Evergreen.V409.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V409.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
        { fileId : Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    | AnswerInput (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    | NotesInput (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V409.Emoji.EmojiOrCustomEmoji (Evergreen.V409.NonemptySet.NonemptySet (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) String
    | ChangedNotes (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V409.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Evergreen.V409.Id.Id Evergreen.V409.Id.UserId )
    , scrollPosition : Evergreen.V409.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
