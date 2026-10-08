module Evergreen.V401.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V401.Emoji
import Evergreen.V401.FileStatus
import Evergreen.V401.Id
import Evergreen.V401.IdArray
import Evergreen.V401.MessageInput
import Evergreen.V401.MessageView
import Evergreen.V401.NonemptySet
import Evergreen.V401.RichText
import Evergreen.V401.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    | NotesReaction (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) Evergreen.V401.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
        { fileId : Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) String
    | TypedNotes (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) Evergreen.V401.MessageInput.Msg
    | GotNotesFiles (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
        { fileId : Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    | ExitedQuestion (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Evergreen.V401.Id.Id Evergreen.V401.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Evergreen.V401.Id.Id Evergreen.V401.Id.UserId )
    | UserScrolledResults Evergreen.V401.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V401.MessageView.MessageViewMsg
    | PressedImage Evergreen.V401.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) Evergreen.V401.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V401.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
        { fileId : Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    | AnswerInput (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    | NotesInput (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V401.Emoji.EmojiOrCustomEmoji (Evergreen.V401.NonemptySet.NonemptySet (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V401.RichText.RichText (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) String
    | ChangedNotes (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V401.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Evergreen.V401.Id.Id Evergreen.V401.Id.UserId )
    , scrollPosition : Evergreen.V401.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
