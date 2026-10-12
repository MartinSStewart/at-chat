module Evergreen.V404.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V404.Emoji
import Evergreen.V404.FileStatus
import Evergreen.V404.Id
import Evergreen.V404.IdArray
import Evergreen.V404.MessageInput
import Evergreen.V404.MessageView
import Evergreen.V404.NonemptySet
import Evergreen.V404.RichText
import Evergreen.V404.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    | NotesReaction (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) Evergreen.V404.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V404.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
        { fileId : Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) String
    | TypedNotes (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) Evergreen.V404.MessageInput.Msg
    | GotNotesFiles (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V404.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
        { fileId : Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    | ExitedQuestion (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V404.Id.Id Evergreen.V404.Id.UserId, Evergreen.V404.Id.Id Evergreen.V404.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V404.Id.Id Evergreen.V404.Id.UserId, Evergreen.V404.Id.Id Evergreen.V404.Id.UserId )
    | UserScrolledResults Evergreen.V404.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V404.MessageView.MessageViewMsg
    | PressedImage Evergreen.V404.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) Evergreen.V404.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V404.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
        { fileId : Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    | AnswerInput (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    | NotesInput (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V404.Emoji.EmojiOrCustomEmoji (Evergreen.V404.NonemptySet.NonemptySet (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V404.RichText.RichText (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId) Evergreen.V404.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) String
    | ChangedNotes (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V404.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V404.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V404.Id.Id Evergreen.V404.Id.UserId, Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId) Evergreen.V404.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V404.Id.Id Evergreen.V404.Id.UserId, Evergreen.V404.Id.Id Evergreen.V404.Id.UserId )
    , scrollPosition : Evergreen.V404.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
