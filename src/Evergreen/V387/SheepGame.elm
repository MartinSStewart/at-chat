module Evergreen.V387.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V387.Emoji
import Evergreen.V387.FileStatus
import Evergreen.V387.Id
import Evergreen.V387.IdArray
import Evergreen.V387.MessageInput
import Evergreen.V387.MessageView
import Evergreen.V387.NonemptySet
import Evergreen.V387.RichText
import Evergreen.V387.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)
    | NotesReaction (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) Evergreen.V387.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)
        { fileId : Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) String
    | TypedNotes (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) Evergreen.V387.MessageInput.Msg
    | GotNotesFiles (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)
        { fileId : Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Evergreen.V387.Id.Id Evergreen.V387.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Evergreen.V387.Id.Id Evergreen.V387.Id.UserId )
    | UserScrolledResults Evergreen.V387.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V387.MessageView.MessageViewMsg
    | PressedImage Evergreen.V387.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) Evergreen.V387.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V387.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)
        { fileId : Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)
    | AnswerInput (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)
    | NotesInput (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V387.Emoji.EmojiOrCustomEmoji (Evergreen.V387.NonemptySet.NonemptySet (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V387.RichText.RichText (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) String
    | ChangedNotes (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V387.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.FileStatus.FileId) Evergreen.V387.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Evergreen.V387.Id.Id Evergreen.V387.Id.UserId )
    , scrollPosition : Evergreen.V387.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
