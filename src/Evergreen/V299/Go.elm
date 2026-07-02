module Evergreen.V299.Go exposing (..)

import Array
import Dict
import Duration
import Effect.Time
import Evergreen.V299.Id
import Evergreen.V299.User


type SpectatorMsg
    = PressedArrowLeft
    | PressedArrowRight
    | ChangedViewingMove Int
    | Spectator_PressedCell ( Int, Int )


type GameMsg
    = PressedCell ( Int, Int )
    | PressedPass
    | PressedDoneMarking
    | PressedAgree
    | PressedDisagree
    | SpectatorMsg SpectatorMsg


type SizeSelection
    = Standard9
    | Standard13
    | Standard19
    | CustomSize


type Stone
    = Black
    | White


type SetupMsg
    = ChangedWidthInput String
    | ChangedHeightInput String
    | ChangedHandicapInput String
    | ChangedKomiInput String
    | ChangedMainTimeInput String
    | ChangedIncrementInput String
    | SelectedSize SizeSelection
    | SelectedPlayingAs Stone
    | PressedStartGame


type BoardSize
    = BoardSize Int


type KomiHalfPoints
    = KomiHalfPoints Int


type alias TimeControl =
    { mainTime : Duration.Duration
    , increment : Duration.Duration
    }


type alias ValidatedSetup =
    { width : BoardSize
    , height : BoardSize
    , handicap : Int
    , komiHalfPoints : KomiHalfPoints
    , timeControl : Maybe TimeControl
    , blackPlayer : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , whitePlayer : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    }


type Action
    = PlaceStone Int Int
    | PassTurn
    | MarkTerritory Int Int
    | FinishedMarking
    | AcceptTerritory
    | RejectTerritory


type alias ActionWithTime =
    { time : Effect.Time.Posix
    , change : Action
    }


type Phase
    = Playing
        { previousPlayerPassed : Bool
        }
    | Marking
    | Confirming
    | Scored
        { blackScore : Float
        , whiteScore : Float
        }


type alias Snapshot =
    { board : Dict.Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , blackCaptures : Int
    , whiteCaptures : Int
    }


type alias Shared =
    { board : Dict.Dict ( Int, Int ) Stone
    , lastMove : Maybe ( Int, Int )
    , blackCaptures : Int
    , whiteCaptures : Int
    , territoryMarks : Dict.Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , phase : Phase
    , lastAction : Maybe Effect.Time.Posix
    , timeLeft :
        Maybe
            { white : Duration.Duration
            , black : Duration.Duration
            }
    , history : List Snapshot
    }


type alias PublicGoMatchData =
    { setup : ValidatedSetup
    , actions : Array.Array ActionWithTime
    , cache : Shared
    , blackPlayer : Evergreen.V299.User.FrontendUser
    , whitePlayer : Evergreen.V299.User.FrontendUser
    }


type alias GameModel =
    { viewingMovesBack : Int
    , lastError : Maybe String
    , lastPlacedStone : Maybe Effect.Time.Posix
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias SetupModel =
    { widthInput : String
    , heightInput : String
    , handicapInput : String
    , komiInput : String
    , mainTimeInput : String
    , incrementInput : String
    , sizeSelection : SizeSelection
    , gameCreatorPlayingAs : Stone
    , error : Maybe String
    }


type alias PublicGoMatchResponse =
    { setup : ValidatedSetup
    , actions : Array.Array ActionWithTime
    , blackPlayer : Evergreen.V299.User.FrontendUser
    , whitePlayer : Evergreen.V299.User.FrontendUser
    }
