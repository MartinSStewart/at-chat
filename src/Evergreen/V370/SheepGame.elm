module Evergreen.V370.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V370.Emoji
import Evergreen.V370.FileStatus
import Evergreen.V370.Id
import Evergreen.V370.IdArray
import Evergreen.V370.MessageInput
import Evergreen.V370.MessageView
import Evergreen.V370.NonemptySet
import Evergreen.V370.RichText
import Evergreen.V370.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)
    | NotesReaction (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) Evergreen.V370.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)
        { fileId : Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) String
    | TypedNotes (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) Evergreen.V370.MessageInput.Msg
    | GotNotesFiles (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)
        { fileId : Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Evergreen.V370.Id.Id Evergreen.V370.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Evergreen.V370.Id.Id Evergreen.V370.Id.UserId )
    | UserScrolledResults Evergreen.V370.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V370.MessageView.MessageViewMsg
    | PressedImage Evergreen.V370.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) Evergreen.V370.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V370.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)
        { fileId : Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)
    | AnswerInput (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)
    | NotesInput (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V370.Emoji.EmojiOrCustomEmoji (Evergreen.V370.NonemptySet.NonemptySet (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V370.RichText.RichText (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) String
    | ChangedNotes (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V370.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Evergreen.V370.Id.Id Evergreen.V370.Id.UserId )
    , scrollPosition : Evergreen.V370.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
