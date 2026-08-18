module Evergreen.V357.SheepGame exposing (..)

import Array
import Dict
import Effect.Time
import Evergreen.V357.Id
import Evergreen.V357.RichText
import List.Nonempty
import SeqDict


type GameMsg
    = TypedAnswer Int String
    | PressedSubmitAnswers
    | PressedLockAnswers
    | TypedGroup (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Int String
    | TypedNotes Int String
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion
    | NoOp


type SetupMsg
    = TypedQuestion Int String
    | PressedAddQuestion
    | PressedRemoveQuestion Int
    | PressedStartGame
    | PressedCancel


type alias Content =
    List.Nonempty.Nonempty (Evergreen.V357.RichText.RichText (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))


type alias ValidatedSetup =
    { questions : List.Nonempty.Nonempty Content
    , createdBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    }


type Action
    = SubmittedAnswers (Array.Array (Maybe Content))
    | LockedAnswers
    | ChangedGroup (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Int String
    | ChangedNotes Int String
    | FinishedGrouping
    | ChangedQuestionsRevealed Int


type alias ActionWithTime =
    { userId : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Answering
    | Grouping
    | Revealing


type alias Shared =
    { phase : Phase
    , answers : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Array.Array (Maybe Content))
    , groups : SeqDict.SeqDict ( Evergreen.V357.Id.Id Evergreen.V357.Id.UserId, Int ) String
    , notes : Dict.Dict Int String
    , questionsRevealed : Int
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias GameData =
    { answerDrafts : Array.Array String
    }


type alias SetupModel =
    { questions : Array.Array String
    , error : Maybe String
    }
