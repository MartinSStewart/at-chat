module Evergreen.V285.Go exposing (..)

import Array
import Dict
import Effect.Time
import Evergreen.V285.Id
import Evergreen.V285.SecretId
import Evergreen.V285.User
import Evergreen.V285.UserSession


type BoardSize
    = BoardSize Int


type KomiHalfPoints
    = KomiHalfPoints Int


type alias TimeControl =
    { mainTime : Float
    , increment : Float
    }


type alias ValidatedSetup =
    { width : BoardSize
    , height : BoardSize
    , handicap : Int
    , komiHalfPoints : KomiHalfPoints
    , timeControl : Maybe TimeControl
    , blackPlayer : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , whitePlayer : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
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


type Stone
    = Black
    | White


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


type alias GameState =
    { board : Dict.Dict ( Int, Int ) Stone
    , lastMove : Maybe ( Int, Int )
    , blackCaptures : Int
    , whiteCaptures : Int
    , territoryMarks : Dict.Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , phase : Phase
    , lastTick : Maybe Effect.Time.Posix
    , blackTime : Float
    , whiteTime : Float
    , history : List Snapshot
    }


type MatchData
    = MatchData
        { setup : ValidatedSetup
        , actions : Array.Array ActionWithTime
        , cache : GameState
        , publicLink : Maybe (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.GoMatchPublicId)
        }


type alias PublicGoMatchData =
    { setup : ValidatedSetup
    , actions : Array.Array ActionWithTime
    , cache : GameState
    , blackPlayer : Evergreen.V285.User.FrontendUser
    , whitePlayer : Evergreen.V285.User.FrontendUser
    }


type alias GameModel =
    { viewingMovesBack : Int
    , lastError : Maybe String
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) ActionWithTime
    | CreatePublicLink (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.UserSession.ToBeFilledInByBackend (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.GoMatchPublicId))


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
    , gameCreatorPlayingAs : Stone
    , error : Maybe String
    }


type Model
    = Setup SetupModel
    | Game GameModel


type alias PublicGoMatchResponse =
    { setup : ValidatedSetup
    , actions : Array.Array ActionWithTime
    , blackPlayer : Evergreen.V285.User.FrontendUser
    , whitePlayer : Evergreen.V285.User.FrontendUser
    }


type SpectatorMsg
    = PressedArrowLeft
    | PressedArrowRight
    | ChangedViewingMove Int


type GameMsg
    = PressedCell Int Int
    | PressedPass
    | PressedDoneMarking
    | PressedAgree
    | PressedDisagree
    | SpectatorMsg SpectatorMsg


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


type Msg
    = GameMsg GameMsg
    | SetupMsg SetupMsg
    | SelectedMatch (Maybe (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId))
    | PressedReset
    | PressedShareGoMatch (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)
    | PressedCopyLink String
    | NoOpMsg
