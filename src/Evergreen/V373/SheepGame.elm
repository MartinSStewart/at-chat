module Evergreen.V373.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V373.Emoji
import Evergreen.V373.FileStatus
import Evergreen.V373.Id
import Evergreen.V373.IdArray
import Evergreen.V373.MessageInput
import Evergreen.V373.MessageView
import Evergreen.V373.NonemptySet
import Evergreen.V373.RichText
import Evergreen.V373.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)
    | NotesReaction (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) Evergreen.V373.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)
        { fileId : Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) String
    | TypedNotes (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) Evergreen.V373.MessageInput.Msg
    | GotNotesFiles (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)
        { fileId : Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Evergreen.V373.Id.Id Evergreen.V373.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Evergreen.V373.Id.Id Evergreen.V373.Id.UserId )
    | UserScrolledResults Evergreen.V373.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V373.MessageView.MessageViewMsg
    | PressedImage Evergreen.V373.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) Evergreen.V373.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V373.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)
        { fileId : Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)
    | AnswerInput (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)
    | NotesInput (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V373.Emoji.EmojiOrCustomEmoji (Evergreen.V373.NonemptySet.NonemptySet (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V373.RichText.RichText (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V373.Id.Id Evergreen.V373.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) String
    | ChangedNotes (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V373.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V373.Id.Id Evergreen.V373.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Evergreen.V373.Id.Id Evergreen.V373.Id.UserId )
    , scrollPosition : Evergreen.V373.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
