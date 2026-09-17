module Evergreen.V383.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V383.Emoji
import Evergreen.V383.FileStatus
import Evergreen.V383.Id
import Evergreen.V383.IdArray
import Evergreen.V383.MessageInput
import Evergreen.V383.MessageView
import Evergreen.V383.NonemptySet
import Evergreen.V383.RichText
import Evergreen.V383.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)
    | NotesReaction (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) Evergreen.V383.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)
        { fileId : Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) String
    | TypedNotes (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) Evergreen.V383.MessageInput.Msg
    | GotNotesFiles (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)
        { fileId : Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Evergreen.V383.Id.Id Evergreen.V383.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Evergreen.V383.Id.Id Evergreen.V383.Id.UserId )
    | UserScrolledResults Evergreen.V383.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V383.MessageView.MessageViewMsg
    | PressedImage Evergreen.V383.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) Evergreen.V383.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V383.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)
        { fileId : Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)
    | AnswerInput (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)
    | NotesInput (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V383.Emoji.EmojiOrCustomEmoji (Evergreen.V383.NonemptySet.NonemptySet (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V383.RichText.RichText (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) String
    | ChangedNotes (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V383.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Evergreen.V383.Id.Id Evergreen.V383.Id.UserId )
    , scrollPosition : Evergreen.V383.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
