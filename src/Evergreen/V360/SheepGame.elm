module Evergreen.V360.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V360.FileStatus
import Evergreen.V360.Id
import Evergreen.V360.IdArray
import Evergreen.V360.MessageInput
import Evergreen.V360.RichText
import List.Nonempty
import SeqDict


type QuestionId
    = QuestionId Never


type GameMsg
    = TypedAnswer (Evergreen.V360.Id.Id QuestionId) Evergreen.V360.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V360.Id.Id QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V360.Id.Id QuestionId)
        { fileId : Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Id.Id QuestionId) String
    | TypedNotes (Evergreen.V360.Id.Id QuestionId) Evergreen.V360.MessageInput.Msg
    | GotNotesFiles (Evergreen.V360.Id.Id QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V360.Id.Id QuestionId)
        { fileId : Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V360.Id.Id Evergreen.V360.Id.UserId, Evergreen.V360.Id.Id Evergreen.V360.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V360.Id.Id Evergreen.V360.Id.UserId, Evergreen.V360.Id.Id Evergreen.V360.Id.UserId )
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V360.Id.Id QuestionId) Evergreen.V360.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V360.Id.Id QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V360.Id.Id QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V360.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V360.Id.Id QuestionId) (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V360.Id.Id QuestionId)
        { fileId : Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V360.Id.Id QuestionId)
    | AnswerInput (Evergreen.V360.Id.Id QuestionId)
    | NotesInput (Evergreen.V360.Id.Id QuestionId)


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V360.RichText.RichText (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileData
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V360.Id.Id QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Id.Id QuestionId) String
    | ChangedNotes (Evergreen.V360.Id.Id QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V360.Id.Id QuestionId)


type alias ActionWithTime =
    { userId : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.IdArray.IdArray QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V360.Id.Id Evergreen.V360.Id.UserId, Evergreen.V360.Id.Id QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V360.Id.Id QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V360.IdArray.IdArray QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V360.IdArray.IdArray QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V360.Id.Id Evergreen.V360.Id.UserId, Evergreen.V360.Id.Id Evergreen.V360.Id.UserId )
    }


type alias SetupModel =
    { questions : Evergreen.V360.IdArray.IdArray QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
