module Evergreen.V295.WordSpellingGame exposing (..)

import Array
import Effect.Time
import Evergreen.V295.Go
import Evergreen.V295.Id
import Evergreen.V295.IdArray
import Evergreen.V295.NonemptyDict
import Evergreen.V295.OneOrGreater
import Evergreen.V295.UserSession
import List.Nonempty
import SeqDict


type Letter
    = A
    | B
    | C
    | D
    | E
    | F
    | G
    | H
    | I
    | J
    | K
    | L
    | M
    | N
    | O
    | P
    | Q
    | R
    | S
    | T
    | U
    | V
    | W
    | X
    | Y
    | Z


type LetterOrWildcard
    = Letter Letter
    | Wildcard


type alias ValidatedSetup =
    { timeControls : Evergreen.V295.Go.TimeControl
    , traySize : Evergreen.V295.OneOrGreater.OneOrGreater
    , createdBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , seed : Int
    , letters : Evergreen.V295.NonemptyDict.NonemptyDict LetterOrWildcard Evergreen.V295.OneOrGreater.OneOrGreater
    }


type alias PlacedWord =
    { start : ( Int, Int )
    , isVertical : Bool
    , letters : List.Nonempty.Nonempty Letter
    }


type IsValid
    = IsValid
    | IsNotValid


type Action
    = PlaceWord PlacedWord (Evergreen.V295.UserSession.ToBeFilledInByBackend IsValid)
    | ReplaceTray
    | JoinGame


type alias ActionWithTime =
    { userId : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type LetterId
    = LetterId Never


type alias Player =
    { userId : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , tray : Evergreen.V295.IdArray.IdArray LetterId LetterOrWildcard
    , score : Int
    }


type alias AnimatedPlacement =
    { startTime : Effect.Time.Posix
    , cells : List ( ( Int, Int ), Letter )
    , isValid : Evergreen.V295.UserSession.ToBeFilledInByBackend IsValid
    }


type alias Shared =
    { board :
        SeqDict.SeqDict
            ( Int, Int )
            { letter : Letter
            , isWildcard : Bool
            }
    , players : List.Nonempty.Nonempty Player
    , turnCount : Int
    , lastPlacement : Maybe AnimatedPlacement
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias SetupModel =
    { mainTimeInput : String
    , incrementInput : String
    , traySize : Int
    , error : Maybe String
    , letters : String
    }


type TrayIndex
    = TrayIndex Int


type TilePosition
    = TileInTray TrayIndex
    | TileOnBoard ( Int, Int )


type alias Tile =
    { position : TilePosition
    , createdAt : Effect.Time.Posix
    }


type alias GameData =
    { selectedCell : Maybe ( Int, Int )
    , tiles : Array.Array Tile
    , dragging : Maybe Int
    }


type Model
    = Setup SetupModel
    | Game GameData


type GameMsg
    = PressedSubmitWord
    | PressedJoinGame
    | PressedReplaceTray


type SetupMsg
    = ChangedMainTimeInput String
    | ChangedIncrementInput String
    | ChangedTraySizeInput String
    | ChangedLettersInput String
    | PressedResetLetters
    | PressedStartGame
