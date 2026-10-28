module Evergreen.V419.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V419.Emoji
import Evergreen.V419.FileStatus
import Evergreen.V419.Id
import Evergreen.V419.IdArray
import Evergreen.V419.MessageInput
import Evergreen.V419.MessageView
import Evergreen.V419.NonemptySet
import Evergreen.V419.RichText
import Evergreen.V419.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    | NotesReaction (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) Evergreen.V419.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
        { fileId : Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) String
    | TypedNotes (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) Evergreen.V419.MessageInput.Msg
    | GotNotesFiles (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
        { fileId : Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    | ExitedQuestion (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Evergreen.V419.Id.Id Evergreen.V419.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Evergreen.V419.Id.Id Evergreen.V419.Id.UserId )
    | UserScrolledResults Evergreen.V419.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V419.MessageView.MessageViewMsg
    | PressedImage Evergreen.V419.RichText.PressedImageData
    | PressedCopyCode String
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) Evergreen.V419.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V419.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
        { fileId : Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    | AnswerInput (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    | NotesInput (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V419.Emoji.EmojiOrCustomEmoji (Evergreen.V419.NonemptySet.NonemptySet (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) String
    | ChangedNotes (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V419.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Evergreen.V419.Id.Id Evergreen.V419.Id.UserId )
    , scrollPosition : Evergreen.V419.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
