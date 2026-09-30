module Evergreen.V395.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V395.Emoji
import Evergreen.V395.FileStatus
import Evergreen.V395.Id
import Evergreen.V395.IdArray
import Evergreen.V395.MessageInput
import Evergreen.V395.MessageView
import Evergreen.V395.NonemptySet
import Evergreen.V395.RichText
import Evergreen.V395.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
    | NotesReaction (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) Evergreen.V395.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
        { fileId : Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) String
    | TypedNotes (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) Evergreen.V395.MessageInput.Msg
    | GotNotesFiles (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
        { fileId : Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Evergreen.V395.Id.Id Evergreen.V395.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Evergreen.V395.Id.Id Evergreen.V395.Id.UserId )
    | UserScrolledResults Evergreen.V395.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V395.MessageView.MessageViewMsg
    | PressedImage Evergreen.V395.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) Evergreen.V395.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V395.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
        { fileId : Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
    | AnswerInput (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
    | NotesInput (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V395.Emoji.EmojiOrCustomEmoji (Evergreen.V395.NonemptySet.NonemptySet (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V395.RichText.RichText (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) String
    | ChangedNotes (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V395.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Evergreen.V395.Id.Id Evergreen.V395.Id.UserId )
    , scrollPosition : Evergreen.V395.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
