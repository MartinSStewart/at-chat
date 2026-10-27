module Evergreen.V417.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V417.Emoji
import Evergreen.V417.FileStatus
import Evergreen.V417.Id
import Evergreen.V417.IdArray
import Evergreen.V417.MessageInput
import Evergreen.V417.MessageView
import Evergreen.V417.NonemptySet
import Evergreen.V417.RichText
import Evergreen.V417.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    | NotesReaction (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) Evergreen.V417.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
        { fileId : Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) String
    | TypedNotes (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) Evergreen.V417.MessageInput.Msg
    | GotNotesFiles (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
        { fileId : Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    | ExitedQuestion (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Evergreen.V417.Id.Id Evergreen.V417.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Evergreen.V417.Id.Id Evergreen.V417.Id.UserId )
    | UserScrolledResults Evergreen.V417.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V417.MessageView.MessageViewMsg
    | PressedImage Evergreen.V417.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) Evergreen.V417.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V417.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
        { fileId : Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    | AnswerInput (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    | NotesInput (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V417.Emoji.EmojiOrCustomEmoji (Evergreen.V417.NonemptySet.NonemptySet (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) String
    | ChangedNotes (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V417.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Evergreen.V417.Id.Id Evergreen.V417.Id.UserId )
    , scrollPosition : Evergreen.V417.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
