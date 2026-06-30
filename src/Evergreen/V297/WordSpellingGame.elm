module Evergreen.V297.WordSpellingGame exposing (..)

import Array
import Effect.Time
import Evergreen.V297.Go
import Evergreen.V297.Id
import Evergreen.V297.IdArray
import Evergreen.V297.NonemptyDict
import Evergreen.V297.OneOrGreater
import Evergreen.V297.UserSession
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
    { timeControls : Evergreen.V297.Go.TimeControl
    , traySize : Evergreen.V297.OneOrGreater.OneOrGreater
    , createdBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , seed : Int
    , letters : Evergreen.V297.NonemptyDict.NonemptyDict LetterOrWildcard Evergreen.V297.OneOrGreater.OneOrGreater
    }


type alias PlacedWord =
    { start : ( Int, Int )
    , isVertical : Bool
    , letters : List.Nonempty.Nonempty LetterOrWildcard
    }


type IsValid
    = IsValid
    | IsNotValid


type Action
    = PlaceWord PlacedWord (Evergreen.V297.UserSession.ToBeFilledInByBackend IsValid)
    | ReplaceTrayOrPass
    | JoinGame


type alias ActionWithTime =
    { userId : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type LetterId
    = LetterId Never


type alias Player =
    { userId : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , tray : Evergreen.V297.IdArray.IdArray LetterId LetterOrWildcard
    , score : Int
    }


type alias AnimatedPlacement =
    { startTime : Effect.Time.Posix
    , cells : List ( ( Int, Int ), LetterOrWildcard )
    , isValid : Evergreen.V297.UserSession.ToBeFilledInByBackend IsValid
    }


type alias Shared =
    { board : SeqDict.SeqDict ( Int, Int ) LetterOrWildcard
    , players : List.Nonempty.Nonempty Player
    , turnCount : Int
    , passingStartedAt : Maybe Int
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
    = TileInTray TrayIndex (Maybe ( Effect.Time.Posix, Int ))
    | TileOnBoard ( Int, Int )


type alias Tile =
    { position : TilePosition
    , createdAt : Effect.Time.Posix
    }


type alias GameData =
    { selectedCell : Maybe ( Int, Int )
    , tiles : Array.Array Tile
    , dragging : Maybe Int
    , invalidPlacement : Maybe Effect.Time.Posix
    }


type Model
    = Setup SetupModel
    | Game GameData


type GameMsg
    = PressedSubmitWord
    | PressedJoinGame
    | PressedReplaceTrayOrPass


type SetupMsg
    = ChangedMainTimeInput String
    | ChangedIncrementInput String
    | ChangedTraySizeInput String
    | ChangedLettersInput String
    | PressedResetLetters
    | PressedStartGame
