module Evergreen.V365.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V365.Emoji
import Evergreen.V365.FileStatus
import Evergreen.V365.Id
import Evergreen.V365.IdArray
import Evergreen.V365.MessageInput
import Evergreen.V365.MessageView
import Evergreen.V365.NonemptySet
import Evergreen.V365.RichText
import Evergreen.V365.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)
    | NotesReaction (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) Evergreen.V365.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)
        { fileId : Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) String
    | TypedNotes (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) Evergreen.V365.MessageInput.Msg
    | GotNotesFiles (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)
        { fileId : Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V365.Id.Id Evergreen.V365.Id.UserId, Evergreen.V365.Id.Id Evergreen.V365.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V365.Id.Id Evergreen.V365.Id.UserId, Evergreen.V365.Id.Id Evergreen.V365.Id.UserId )
    | UserScrolledResults Evergreen.V365.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V365.MessageView.MessageViewMsg
    | PressedImage Evergreen.V365.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) Evergreen.V365.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V365.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)
        { fileId : Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)
    | AnswerInput (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)
    | NotesInput (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V365.Emoji.EmojiOrCustomEmoji (Evergreen.V365.NonemptySet.NonemptySet (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V365.RichText.RichText (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) String
    | ChangedNotes (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V365.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V365.Id.Id Evergreen.V365.Id.UserId, Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V365.Id.Id Evergreen.V365.Id.UserId, Evergreen.V365.Id.Id Evergreen.V365.Id.UserId )
    , scrollPosition : Evergreen.V365.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
