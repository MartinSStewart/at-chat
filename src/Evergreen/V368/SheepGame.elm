module Evergreen.V368.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V368.Emoji
import Evergreen.V368.FileStatus
import Evergreen.V368.Id
import Evergreen.V368.IdArray
import Evergreen.V368.MessageInput
import Evergreen.V368.MessageView
import Evergreen.V368.NonemptySet
import Evergreen.V368.RichText
import Evergreen.V368.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)
    | NotesReaction (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) Evergreen.V368.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)
        { fileId : Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) String
    | TypedNotes (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) Evergreen.V368.MessageInput.Msg
    | GotNotesFiles (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)
        { fileId : Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Evergreen.V368.Id.Id Evergreen.V368.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Evergreen.V368.Id.Id Evergreen.V368.Id.UserId )
    | UserScrolledResults Evergreen.V368.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V368.MessageView.MessageViewMsg
    | PressedImage Evergreen.V368.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) Evergreen.V368.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V368.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)
        { fileId : Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)
    | AnswerInput (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)
    | NotesInput (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V368.Emoji.EmojiOrCustomEmoji (Evergreen.V368.NonemptySet.NonemptySet (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V368.RichText.RichText (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) String
    | ChangedNotes (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V368.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Evergreen.V368.Id.Id Evergreen.V368.Id.UserId )
    , scrollPosition : Evergreen.V368.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
