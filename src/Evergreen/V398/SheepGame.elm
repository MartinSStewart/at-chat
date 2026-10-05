module Evergreen.V398.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V398.Emoji
import Evergreen.V398.FileStatus
import Evergreen.V398.Id
import Evergreen.V398.IdArray
import Evergreen.V398.MessageInput
import Evergreen.V398.MessageView
import Evergreen.V398.NonemptySet
import Evergreen.V398.RichText
import Evergreen.V398.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
    | NotesReaction (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) Evergreen.V398.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
        { fileId : Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) String
    | TypedNotes (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) Evergreen.V398.MessageInput.Msg
    | GotNotesFiles (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
        { fileId : Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
    | ExitedQuestion (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Evergreen.V398.Id.Id Evergreen.V398.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Evergreen.V398.Id.Id Evergreen.V398.Id.UserId )
    | UserScrolledResults Evergreen.V398.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V398.MessageView.MessageViewMsg
    | PressedImage Evergreen.V398.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) Evergreen.V398.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V398.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
        { fileId : Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
    | AnswerInput (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
    | NotesInput (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V398.Emoji.EmojiOrCustomEmoji (Evergreen.V398.NonemptySet.NonemptySet (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V398.RichText.RichText (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) String
    | ChangedNotes (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V398.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId) Evergreen.V398.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Evergreen.V398.Id.Id Evergreen.V398.Id.UserId )
    , scrollPosition : Evergreen.V398.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V398.Id.Id Evergreen.V398.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
