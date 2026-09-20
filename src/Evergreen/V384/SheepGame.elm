module Evergreen.V384.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V384.Emoji
import Evergreen.V384.FileStatus
import Evergreen.V384.Id
import Evergreen.V384.IdArray
import Evergreen.V384.MessageInput
import Evergreen.V384.MessageView
import Evergreen.V384.NonemptySet
import Evergreen.V384.RichText
import Evergreen.V384.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)
    | NotesReaction (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) Evergreen.V384.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)
        { fileId : Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) String
    | TypedNotes (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) Evergreen.V384.MessageInput.Msg
    | GotNotesFiles (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)
        { fileId : Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Evergreen.V384.Id.Id Evergreen.V384.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Evergreen.V384.Id.Id Evergreen.V384.Id.UserId )
    | UserScrolledResults Evergreen.V384.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V384.MessageView.MessageViewMsg
    | PressedImage Evergreen.V384.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) Evergreen.V384.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V384.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)
        { fileId : Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)
    | AnswerInput (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)
    | NotesInput (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V384.Emoji.EmojiOrCustomEmoji (Evergreen.V384.NonemptySet.NonemptySet (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V384.RichText.RichText (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) String
    | ChangedNotes (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V384.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId) Evergreen.V384.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Evergreen.V384.Id.Id Evergreen.V384.Id.UserId )
    , scrollPosition : Evergreen.V384.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
