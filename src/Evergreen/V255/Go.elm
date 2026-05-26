module Evergreen.V255.Go exposing (..)

import Array
import Effect.Time
import Evergreen.V255.Id
import Evergreen.V255.SecretId
import Evergreen.V255.User
import Evergreen.V255.UserSession


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
    , blackPlayer : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , whitePlayer : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
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


type alias PublicGoMatchData =
    { setup : ValidatedSetup
    , actions : Array.Array ActionWithTime
    , blackPlayer : Evergreen.V255.User.FrontendUser
    , whitePlayer : Evergreen.V255.User.FrontendUser
    }


type alias GameModel =
    { viewingMovesBack : Int
    , lastError : Maybe String
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) ActionWithTime
    | CreatePublicLink (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.UserSession.ToBeFilledInByBackend (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.GoMatchPublicId))


type SizeSelection
    = Standard9
    | Standard13
    | Standard19
    | CustomSize


type Stone
    = Black
    | White


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
    | SelectedMatch (Maybe (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId))
    | PressedReset
    | PressedShareGoMatch (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
    | PressedCopyLink String
    | NoOpMsg
