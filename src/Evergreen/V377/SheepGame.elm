module Evergreen.V377.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V377.Emoji
import Evergreen.V377.FileStatus
import Evergreen.V377.Id
import Evergreen.V377.IdArray
import Evergreen.V377.MessageInput
import Evergreen.V377.MessageView
import Evergreen.V377.NonemptySet
import Evergreen.V377.RichText
import Evergreen.V377.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)
    | NotesReaction (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) Evergreen.V377.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)
        { fileId : Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) String
    | TypedNotes (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) Evergreen.V377.MessageInput.Msg
    | GotNotesFiles (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)
        { fileId : Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Evergreen.V377.Id.Id Evergreen.V377.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Evergreen.V377.Id.Id Evergreen.V377.Id.UserId )
    | UserScrolledResults Evergreen.V377.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V377.MessageView.MessageViewMsg
    | PressedImage Evergreen.V377.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) Evergreen.V377.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V377.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)
        { fileId : Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)
    | AnswerInput (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)
    | NotesInput (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V377.Emoji.EmojiOrCustomEmoji (Evergreen.V377.NonemptySet.NonemptySet (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V377.RichText.RichText (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) String
    | ChangedNotes (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V377.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Evergreen.V377.Id.Id Evergreen.V377.Id.UserId )
    , scrollPosition : Evergreen.V377.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
