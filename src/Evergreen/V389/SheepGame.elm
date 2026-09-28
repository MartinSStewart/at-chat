module Evergreen.V389.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V389.Emoji
import Evergreen.V389.FileStatus
import Evergreen.V389.Id
import Evergreen.V389.IdArray
import Evergreen.V389.MessageInput
import Evergreen.V389.MessageView
import Evergreen.V389.NonemptySet
import Evergreen.V389.RichText
import Evergreen.V389.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)
    | NotesReaction (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) Evergreen.V389.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)
        { fileId : Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) String
    | TypedNotes (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) Evergreen.V389.MessageInput.Msg
    | GotNotesFiles (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)
        { fileId : Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Evergreen.V389.Id.Id Evergreen.V389.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Evergreen.V389.Id.Id Evergreen.V389.Id.UserId )
    | UserScrolledResults Evergreen.V389.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V389.MessageView.MessageViewMsg
    | PressedImage Evergreen.V389.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) Evergreen.V389.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V389.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)
        { fileId : Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)
    | AnswerInput (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)
    | NotesInput (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V389.Emoji.EmojiOrCustomEmoji (Evergreen.V389.NonemptySet.NonemptySet (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V389.RichText.RichText (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) String
    | ChangedNotes (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V389.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId) Evergreen.V389.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Evergreen.V389.Id.Id Evergreen.V389.Id.UserId )
    , scrollPosition : Evergreen.V389.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
