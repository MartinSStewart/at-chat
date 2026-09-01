module Evergreen.V366.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V366.Emoji
import Evergreen.V366.FileStatus
import Evergreen.V366.Id
import Evergreen.V366.IdArray
import Evergreen.V366.MessageInput
import Evergreen.V366.MessageView
import Evergreen.V366.NonemptySet
import Evergreen.V366.RichText
import Evergreen.V366.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)
    | NotesReaction (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) Evergreen.V366.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)
        { fileId : Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) String
    | TypedNotes (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) Evergreen.V366.MessageInput.Msg
    | GotNotesFiles (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)
        { fileId : Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V366.Id.Id Evergreen.V366.Id.UserId, Evergreen.V366.Id.Id Evergreen.V366.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V366.Id.Id Evergreen.V366.Id.UserId, Evergreen.V366.Id.Id Evergreen.V366.Id.UserId )
    | UserScrolledResults Evergreen.V366.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V366.MessageView.MessageViewMsg
    | PressedImage Evergreen.V366.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) Evergreen.V366.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V366.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)
        { fileId : Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)
    | AnswerInput (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)
    | NotesInput (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V366.Emoji.EmojiOrCustomEmoji (Evergreen.V366.NonemptySet.NonemptySet (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V366.RichText.RichText (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) String
    | ChangedNotes (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V366.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V366.Id.Id Evergreen.V366.Id.UserId, Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V366.Id.Id Evergreen.V366.Id.UserId, Evergreen.V366.Id.Id Evergreen.V366.Id.UserId )
    , scrollPosition : Evergreen.V366.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
