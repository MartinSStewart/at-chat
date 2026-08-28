module Evergreen.V363.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V363.FileStatus
import Evergreen.V363.Id
import Evergreen.V363.IdArray
import Evergreen.V363.MessageInput
import Evergreen.V363.RichText
import List.Nonempty
import SeqDict


type QuestionId
    = QuestionId Never


type GameMsg
    = TypedAnswer (Evergreen.V363.Id.Id QuestionId) Evergreen.V363.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V363.Id.Id QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V363.Id.Id QuestionId)
        { fileId : Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Id.Id QuestionId) String
    | TypedNotes (Evergreen.V363.Id.Id QuestionId) Evergreen.V363.MessageInput.Msg
    | GotNotesFiles (Evergreen.V363.Id.Id QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V363.Id.Id QuestionId)
        { fileId : Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V363.Id.Id Evergreen.V363.Id.UserId, Evergreen.V363.Id.Id Evergreen.V363.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V363.Id.Id Evergreen.V363.Id.UserId, Evergreen.V363.Id.Id Evergreen.V363.Id.UserId )
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V363.Id.Id QuestionId) Evergreen.V363.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V363.Id.Id QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V363.Id.Id QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V363.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V363.Id.Id QuestionId) (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V363.Id.Id QuestionId)
        { fileId : Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V363.Id.Id QuestionId)
    | AnswerInput (Evergreen.V363.Id.Id QuestionId)
    | NotesInput (Evergreen.V363.Id.Id QuestionId)


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V363.RichText.RichText (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileData
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V363.Id.Id QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Id.Id QuestionId) String
    | ChangedNotes (Evergreen.V363.Id.Id QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V363.Id.Id QuestionId)


type alias ActionWithTime =
    { userId : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.IdArray.IdArray QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V363.Id.Id Evergreen.V363.Id.UserId, Evergreen.V363.Id.Id QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V363.Id.Id QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V363.IdArray.IdArray QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V363.IdArray.IdArray QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V363.Id.Id Evergreen.V363.Id.UserId, Evergreen.V363.Id.Id Evergreen.V363.Id.UserId )
    }


type alias SetupModel =
    { questions : Evergreen.V363.IdArray.IdArray QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
