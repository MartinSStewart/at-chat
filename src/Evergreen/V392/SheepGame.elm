module Evergreen.V392.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V392.Emoji
import Evergreen.V392.FileStatus
import Evergreen.V392.Id
import Evergreen.V392.IdArray
import Evergreen.V392.MessageInput
import Evergreen.V392.MessageView
import Evergreen.V392.NonemptySet
import Evergreen.V392.RichText
import Evergreen.V392.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
    | NotesReaction (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) Evergreen.V392.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
        { fileId : Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) String
    | TypedNotes (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) Evergreen.V392.MessageInput.Msg
    | GotNotesFiles (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
        { fileId : Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Evergreen.V392.Id.Id Evergreen.V392.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Evergreen.V392.Id.Id Evergreen.V392.Id.UserId )
    | UserScrolledResults Evergreen.V392.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V392.MessageView.MessageViewMsg
    | PressedImage Evergreen.V392.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) Evergreen.V392.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V392.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
        { fileId : Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
    | AnswerInput (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
    | NotesInput (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V392.Emoji.EmojiOrCustomEmoji (Evergreen.V392.NonemptySet.NonemptySet (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V392.RichText.RichText (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) String
    | ChangedNotes (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V392.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Evergreen.V392.Id.Id Evergreen.V392.Id.UserId )
    , scrollPosition : Evergreen.V392.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
