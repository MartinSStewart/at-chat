module Evergreen.V396.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V396.Emoji
import Evergreen.V396.FileStatus
import Evergreen.V396.Id
import Evergreen.V396.IdArray
import Evergreen.V396.MessageInput
import Evergreen.V396.MessageView
import Evergreen.V396.NonemptySet
import Evergreen.V396.RichText
import Evergreen.V396.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
    | NotesReaction (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) Evergreen.V396.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
        { fileId : Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) String
    | TypedNotes (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) Evergreen.V396.MessageInput.Msg
    | GotNotesFiles (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
        { fileId : Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
    | ExitedQuestion (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Evergreen.V396.Id.Id Evergreen.V396.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Evergreen.V396.Id.Id Evergreen.V396.Id.UserId )
    | UserScrolledResults Evergreen.V396.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V396.MessageView.MessageViewMsg
    | PressedImage Evergreen.V396.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) Evergreen.V396.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V396.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
        { fileId : Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
    | AnswerInput (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
    | NotesInput (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V396.Emoji.EmojiOrCustomEmoji (Evergreen.V396.NonemptySet.NonemptySet (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V396.RichText.RichText (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) String
    | ChangedNotes (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V396.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId) Evergreen.V396.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Evergreen.V396.Id.Id Evergreen.V396.Id.UserId )
    , scrollPosition : Evergreen.V396.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V396.Id.Id Evergreen.V396.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
