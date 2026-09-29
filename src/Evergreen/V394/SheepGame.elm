module Evergreen.V394.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V394.Emoji
import Evergreen.V394.FileStatus
import Evergreen.V394.Id
import Evergreen.V394.IdArray
import Evergreen.V394.MessageInput
import Evergreen.V394.MessageView
import Evergreen.V394.NonemptySet
import Evergreen.V394.RichText
import Evergreen.V394.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)
    | NotesReaction (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) Evergreen.V394.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)
        { fileId : Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) String
    | TypedNotes (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) Evergreen.V394.MessageInput.Msg
    | GotNotesFiles (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)
        { fileId : Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Evergreen.V394.Id.Id Evergreen.V394.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Evergreen.V394.Id.Id Evergreen.V394.Id.UserId )
    | UserScrolledResults Evergreen.V394.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V394.MessageView.MessageViewMsg
    | PressedImage Evergreen.V394.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) Evergreen.V394.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V394.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)
        { fileId : Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)
    | AnswerInput (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)
    | NotesInput (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V394.Emoji.EmojiOrCustomEmoji (Evergreen.V394.NonemptySet.NonemptySet (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V394.RichText.RichText (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) String
    | ChangedNotes (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V394.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId) Evergreen.V394.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Evergreen.V394.Id.Id Evergreen.V394.Id.UserId )
    , scrollPosition : Evergreen.V394.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
