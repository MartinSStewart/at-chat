module Evergreen.V379.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V379.Emoji
import Evergreen.V379.FileStatus
import Evergreen.V379.Id
import Evergreen.V379.IdArray
import Evergreen.V379.MessageInput
import Evergreen.V379.MessageView
import Evergreen.V379.NonemptySet
import Evergreen.V379.RichText
import Evergreen.V379.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)
    | NotesReaction (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) Evergreen.V379.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)
        { fileId : Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) String
    | TypedNotes (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) Evergreen.V379.MessageInput.Msg
    | GotNotesFiles (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)
        { fileId : Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Evergreen.V379.Id.Id Evergreen.V379.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Evergreen.V379.Id.Id Evergreen.V379.Id.UserId )
    | UserScrolledResults Evergreen.V379.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V379.MessageView.MessageViewMsg
    | PressedImage Evergreen.V379.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) Evergreen.V379.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V379.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)
        { fileId : Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)
    | AnswerInput (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)
    | NotesInput (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V379.Emoji.EmojiOrCustomEmoji (Evergreen.V379.NonemptySet.NonemptySet (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V379.RichText.RichText (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) String
    | ChangedNotes (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V379.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Evergreen.V379.Id.Id Evergreen.V379.Id.UserId )
    , scrollPosition : Evergreen.V379.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
