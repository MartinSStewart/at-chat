module Evergreen.V388.SheepGame exposing (..)

import Effect.File
import Effect.Http
import Effect.Time
import Evergreen.V388.Emoji
import Evergreen.V388.FileStatus
import Evergreen.V388.Id
import Evergreen.V388.IdArray
import Evergreen.V388.MessageInput
import Evergreen.V388.MessageView
import Evergreen.V388.NonemptySet
import Evergreen.V388.RichText
import Evergreen.V388.Scroll
import List.Nonempty
import SeqDict


type ReactionTarget
    = AnswerReaction (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
    | NotesReaction (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)


type GameMsg
    = TypedAnswer (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) Evergreen.V388.MessageInput.Msg
    | GotAnswerFiles (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAnswerFileUpload (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse)
    | PressedDeleteAnswerFile (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedViewAnswerFileInfo (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedToggleAnswerFileSpoiler
        (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
        { fileId : Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedLockAnswers
    | PressedUnlockAnswers
    | TypedGroup (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) String
    | TypedNotes (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) Evergreen.V388.MessageInput.Msg
    | GotNotesFiles (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotNotesFileUpload (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse)
    | PressedDeleteNotesFile (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedViewNotesFileInfo (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedToggleNotesFileSpoiler
        (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
        { fileId : Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | HoveredResultsGrid ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Evergreen.V388.Id.Id Evergreen.V388.Id.UserId )
    | ExitedResultsGrid ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Evergreen.V388.Id.Id Evergreen.V388.Id.UserId )
    | UserScrolledResults Evergreen.V388.Scroll.ScrollPosition
    | ReactionMsg ReactionTarget Evergreen.V388.MessageView.MessageViewMsg
    | PressedImage Evergreen.V388.RichText.PressedImageData
    | PressedNewQuestionRevealed
    | NoOp


type SetupMsg
    = TypedQuestion (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) Evergreen.V388.MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
    | PressedStartGame
    | PressedCancel
    | GotFilesToAttach (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (List.Nonempty.Nonempty Effect.File.File)
    | GotAttachedFileUpload (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V388.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedViewAttachedFileInfo (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
        { fileId : Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId
        , removeSpoiler : Bool
        }


type Input
    = QuestionInput (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
    | AnswerInput (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
    | NotesInput (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)


type alias Reactions =
    SeqDict.SeqDict Evergreen.V388.Emoji.EmojiOrCustomEmoji (Evergreen.V388.NonemptySet.NonemptySet (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId))


type alias ValidatedInput =
    { text : List.Nonempty.Nonempty (Evergreen.V388.RichText.RichText (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))
    , attachedFiles : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileData
    , reactions : Reactions
    }


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty ValidatedInput
    , createdBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    }


type Action
    = SubmittedAnswer (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Maybe ValidatedInput)
    | LockedAnswers
    | UnlockedAnswers
    | ChangedGroup (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) String
    | ChangedNotes (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Maybe ValidatedInput)
    | FinishedGrouping
    | ChangedQuestionsRevealed (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
    | AddedReaction ReactionTarget Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | RemovedReaction ReactionTarget Evergreen.V388.Emoji.EmojiOrCustomEmoji


type alias ActionWithTime =
    { userId : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.QuestionId (Maybe ValidatedInput))
    , groups : SeqDict.SeqDict ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId ) String
    , notes : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId) (Maybe ValidatedInput)
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias UnvalidatedInput =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileStatus
    }


type alias GameData =
    { answerDrafts : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.QuestionId UnvalidatedInput
    , noteDrafts : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.QuestionId UnvalidatedInput
    , gridHovered : Maybe ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Evergreen.V388.Id.Id Evergreen.V388.Id.UserId )
    , scrollPosition : Evergreen.V388.Scroll.ScrollPosition
    , questionsRevealedSeen : Int
    , newQuestionRevealed : Bool
    , hoveredResult : Maybe ReactionTarget
    }


type alias SetupModel =
    { questions : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.QuestionId UnvalidatedInput
    , error : Maybe String
    , pressedSubmit : Bool
    }
