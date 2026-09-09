module Evergreen.V375.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V375.Emoji
import Evergreen.V375.FileStatus
import Evergreen.V375.Id
import Evergreen.V375.IdArray
import Evergreen.V375.MessageInput
import Evergreen.V375.MessageView
import Evergreen.V375.NonemptySet
import Evergreen.V375.RichText
import Evergreen.V375.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)
    | NotesReaction (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) Evergreen.V375.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)
        { fileId : Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) String
    | TypedNotes (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) Evergreen.V375.MessageInput.Msg
    | GotNotesFiles (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)
        { fileId : Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Evergreen.V375.Id.Id Evergreen.V375.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Evergreen.V375.Id.Id Evergreen.V375.Id.UserId )
    | UserScrolledResults Evergreen.V375.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V375.MessageView.MessageViewMsg
    | PressedImage Evergreen.V375.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) Evergreen.V375.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V375.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)
        { fileId : Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)
    | AnswerInput (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)
    | NotesInput (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V375.Emoji.EmojiOrCustomEmoji (Evergreen.V375.NonemptySet.NonemptySet (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V375.RichText.RichText (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) String
    | ChangedNotes (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V375.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Evergreen.V375.Id.Id Evergreen.V375.Id.UserId )
    , scrollPosition : Evergreen.V375.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
