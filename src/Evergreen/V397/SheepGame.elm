module Evergreen.V397.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V397.Emoji
import Evergreen.V397.FileStatus
import Evergreen.V397.Id
import Evergreen.V397.IdArray
import Evergreen.V397.MessageInput
import Evergreen.V397.MessageView
import Evergreen.V397.NonemptySet
import Evergreen.V397.RichText
import Evergreen.V397.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    | NotesReaction (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) Evergreen.V397.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
        { fileId : Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) String
    | TypedNotes (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) Evergreen.V397.MessageInput.Msg
    | GotNotesFiles (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
        { fileId : Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredQuestion (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    | ExitedQuestion (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    | HoveredResultsGrid ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Evergreen.V397.Id.Id Evergreen.V397.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Evergreen.V397.Id.Id Evergreen.V397.Id.UserId )
    | UserScrolledResults Evergreen.V397.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V397.MessageView.MessageViewMsg
    | PressedImage Evergreen.V397.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) Evergreen.V397.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V397.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
        { fileId : Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    | AnswerInput (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    | NotesInput (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V397.Emoji.EmojiOrCustomEmoji (Evergreen.V397.NonemptySet.NonemptySet (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V397.RichText.RichText (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) String
    | ChangedNotes (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V397.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Evergreen.V397.Id.Id Evergreen.V397.Id.UserId )
    , scrollPosition : Evergreen.V397.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    , hoveredQuestion : Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    }


type alias SetupModel =
    { questions : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
