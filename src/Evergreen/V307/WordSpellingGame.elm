module Evergreen.V307.WordSpellingGame exposing (..)

import Array
import Effect.Time
import Evergreen.V307.Go
import Evergreen.V307.Id
import Evergreen.V307.IdArray
import Evergreen.V307.NonemptyDict
import Evergreen.V307.OneOrGreater
import Evergreen.V307.Scroll
import Evergreen.V307.UserSession
import List.Nonempty
import SeqDict


type Letter
    = LetterChar Char


type LetterOrWildcard
    = Letter Letter
    | Wildcard


type alias PlacedWord =
    { start : ( Int, Int )
    , isVertical : Bool
    , letters : List.Nonempty.Nonempty LetterOrWildcard
    }


type GameMsg
    = PressedSubmitWord PlacedWord
    | PressedJoinGame
    | PressedReplaceTrayOrPass
    | PressedClearBoard
    | PressedToggleSettings
    | PressedPlayerRow (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    | MouseEnterPlayerRow (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    | MouseExitPlayerRow (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    | UserScrolledPastMoves Evergreen.V307.Scroll.ScrollPosition


type Language
    = English
    | Swedish


type SetupMsg
    = ChangedMainTimeInput String
    | ChangedIncrementInput String
    | ChangedTraySizeInput String
    | ChangedFullTrayBonusInput String
    | ChangedLettersInput String
    | ChangedLetterValue Char String
    | ChangedPlaceWordAttempts Evergreen.V307.OneOrGreater.OneOrGreater
    | PressedResetLetters
    | PressedStartGame
    | PressedCancel
    | PressedLanguage Language


type alias ValidatedSetup =
    { timeControls : Evergreen.V307.Go.TimeControl
    , traySize : Evergreen.V307.OneOrGreater.OneOrGreater
    , fullTrayBonus : Int
    , createdBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , seed : Int
    , letters :
        Evergreen.V307.NonemptyDict.NonemptyDict
            LetterOrWildcard
            { count : Evergreen.V307.OneOrGreater.OneOrGreater
            , value : Int
            }
    , language : Language
    , placeWordAttempts : Evergreen.V307.OneOrGreater.OneOrGreater
    }


type IsValid
    = IsValid
    | IsNotValid


type Action
    = PlaceWord PlacedWord (Evergreen.V307.UserSession.ToBeFilledInByBackend IsValid)
    | ReplaceTrayOrPass
    | JoinGame


type alias ActionWithTime =
    { userId : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type LetterId
    = LetterId Never


type alias Player =
    { userId : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , tray : Evergreen.V307.IdArray.IdArray LetterId LetterOrWildcard
    , score : Int
    }


type alias AnimatedPlacement =
    { startTime : Effect.Time.Posix
    , cells : List ( ( Int, Int ), LetterOrWildcard )
    , isValid : Evergreen.V307.UserSession.ToBeFilledInByBackend IsValid
    }


type alias Shared =
    { board : SeqDict.SeqDict ( Int, Int ) LetterOrWildcard
    , players : List.Nonempty.Nonempty Player
    , turnCount : Int
    , passingStartedAt : Maybe Int
    , lastPlacement : Maybe AnimatedPlacement
    , attemptsLeft : Evergreen.V307.OneOrGreater.OneOrGreater
    }


type LocalChange
    = StartMatch Effect.Time.Posix ValidatedSetup
    | Action ActionWithTime


type TrayIndex
    = TrayIndex Int


type TilePosition
    = TileInTray TrayIndex (Maybe ( Effect.Time.Posix, Int ))
    | TileOnBoard ( Int, Int ) Effect.Time.Posix


type alias Tile =
    { position : TilePosition
    , createdAt : Effect.Time.Posix
    }


type Drag
    = Dragging Int
    | NotDragging


type alias ZoomState =
    { amount : Float
    , focusX : Float
    , focusY : Float
    }


type alias ZoomAnimation =
    { start : Effect.Time.Posix
    , from : ZoomState
    }


type alias GameData =
    { selectedCell : Maybe ( Int, Int )
    , tiles : Array.Array Tile
    , dragging : Drag
    , zoomAnimation : ZoomAnimation
    , lastWordPlaced :
        Maybe
            { time : Effect.Time.Posix
            , letterCount : Int
            }
    , showSettings : Bool
    , highlightedPlayer : Maybe (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    , scrollPosition : Evergreen.V307.Scroll.ScrollPosition
    }


type alias SetupModel =
    { mainTimeInput : String
    , incrementInput : String
    , traySize : Int
    , fullTrayBonus : Int
    , error : Maybe String
    , letters : String
    , letterValues : SeqDict.SeqDict Char String
    , language : Language
    , placeWordAttempts : Evergreen.V307.OneOrGreater.OneOrGreater
    }
