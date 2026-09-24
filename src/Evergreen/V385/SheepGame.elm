module Evergreen.V385.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V385.Emoji
import Evergreen.V385.FileStatus
import Evergreen.V385.Id
import Evergreen.V385.IdArray
import Evergreen.V385.MessageInput
import Evergreen.V385.MessageView
import Evergreen.V385.NonemptySet
import Evergreen.V385.RichText
import Evergreen.V385.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
    | NotesReaction (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) Evergreen.V385.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
        { fileId : Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) String
    | TypedNotes (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) Evergreen.V385.MessageInput.Msg
    | GotNotesFiles (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
        { fileId : Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Evergreen.V385.Id.Id Evergreen.V385.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Evergreen.V385.Id.Id Evergreen.V385.Id.UserId )
    | UserScrolledResults Evergreen.V385.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V385.MessageView.MessageViewMsg
    | PressedImage Evergreen.V385.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) Evergreen.V385.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V385.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
        { fileId : Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
    | AnswerInput (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
    | NotesInput (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V385.Emoji.EmojiOrCustomEmoji (Evergreen.V385.NonemptySet.NonemptySet (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V385.RichText.RichText (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) String
    | ChangedNotes (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V385.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Evergreen.V385.Id.Id Evergreen.V385.Id.UserId )
    , scrollPosition : Evergreen.V385.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
