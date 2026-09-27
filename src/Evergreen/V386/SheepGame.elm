module Evergreen.V386.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V386.Emoji
import Evergreen.V386.FileStatus
import Evergreen.V386.Id
import Evergreen.V386.IdArray
import Evergreen.V386.MessageInput
import Evergreen.V386.MessageView
import Evergreen.V386.NonemptySet
import Evergreen.V386.RichText
import Evergreen.V386.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
    | NotesReaction (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) Evergreen.V386.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
        { fileId : Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) String
    | TypedNotes (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) Evergreen.V386.MessageInput.Msg
    | GotNotesFiles (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
        { fileId : Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Evergreen.V386.Id.Id Evergreen.V386.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Evergreen.V386.Id.Id Evergreen.V386.Id.UserId )
    | UserScrolledResults Evergreen.V386.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V386.MessageView.MessageViewMsg
    | PressedImage Evergreen.V386.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) Evergreen.V386.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V386.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
        { fileId : Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
    | AnswerInput (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
    | NotesInput (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V386.Emoji.EmojiOrCustomEmoji (Evergreen.V386.NonemptySet.NonemptySet (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V386.RichText.RichText (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) String
    | ChangedNotes (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V386.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V386.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Evergreen.V386.Id.Id Evergreen.V386.Id.UserId )
    , scrollPosition : Evergreen.V386.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
