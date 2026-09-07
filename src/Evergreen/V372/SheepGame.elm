module Evergreen.V372.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V372.Emoji
import Evergreen.V372.FileStatus
import Evergreen.V372.Id
import Evergreen.V372.IdArray
import Evergreen.V372.MessageInput
import Evergreen.V372.MessageView
import Evergreen.V372.NonemptySet
import Evergreen.V372.RichText
import Evergreen.V372.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)
    | NotesReaction (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) Evergreen.V372.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)
        { fileId : Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) String
    | TypedNotes (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) Evergreen.V372.MessageInput.Msg
    | GotNotesFiles (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)
        { fileId : Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Evergreen.V372.Id.Id Evergreen.V372.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Evergreen.V372.Id.Id Evergreen.V372.Id.UserId )
    | UserScrolledResults Evergreen.V372.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V372.MessageView.MessageViewMsg
    | PressedImage Evergreen.V372.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) Evergreen.V372.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V372.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)
        { fileId : Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)
    | AnswerInput (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)
    | NotesInput (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V372.Emoji.EmojiOrCustomEmoji (Evergreen.V372.NonemptySet.NonemptySet (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V372.RichText.RichText (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) String
    | ChangedNotes (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V372.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Evergreen.V372.Id.Id Evergreen.V372.Id.UserId )
    , scrollPosition : Evergreen.V372.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
