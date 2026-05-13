module Evergreen.V215.Pages.Go exposing (..)

import Dict
import Effect.Time


type SizeSelection
    = Standard9
    | Standard13
    | Standard19
    | CustomSize


type alias SetupModel =
    { widthInput : String
    , heightInput : String
    , handicapInput : String
    , komiInput : String
    , mainTimeInput : String
    , incrementInput : String
    , sizeSelection : SizeSelection
    , error : Maybe String
    }


type alias TimeControl =
    { mainTime : Float
    , increment : Float
    }


type Stone
    = Black
    | White


type alias Snapshot =
    { board : Dict.Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , blackCaptures : Int
    , whiteCaptures : Int
    }


type Phase
    = Playing
        { previousPlayerPassed : Bool
        }
    | Marking
        { markingPlayer : Stone
        }
    | Confirming
        { markingPlayer : Stone
        }
    | Scored
        { markingPlayer : Stone
        , blackScore : Float
        , whiteScore : Float
        }


type alias GameModel =
    { width : Int
    , height : Int
    , komi : Float
    , timeControl : Maybe TimeControl
    , blackTime : Float
    , whiteTime : Float
    , lastTick : Maybe Effect.Time.Posix
    , board : Dict.Dict ( Int, Int ) Stone
    , lastMove : Maybe ( Int, Int )
    , history : List Snapshot
    , viewingMovesBack : Int
    , currentPlayer : Stone
    , blackCaptures : Int
    , whiteCaptures : Int
    , phase : Phase
    , territoryMarks : Dict.Dict ( Int, Int ) Stone
    , lastError : Maybe String
    }


type Model
    = Setup SetupModel
    | Game GameModel


type Msg
    = PressedCell Int Int
    | PressedPass
    | PressedReset
    | PressedDoneMarking
    | PressedAgree
    | PressedDisagree
    | ChangedViewingMove Int
    | PressedArrowLeft
    | PressedArrowRight
    | ChangedWidthInput String
    | ChangedHeightInput String
    | ChangedHandicapInput String
    | ChangedKomiInput String
    | ChangedMainTimeInput String
    | ChangedIncrementInput String
    | SelectedSize SizeSelection
    | PressedStartGame
    | Tick Effect.Time.Posix
