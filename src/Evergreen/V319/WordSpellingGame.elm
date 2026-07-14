module Evergreen.V319.WordSpellingGame exposing (..)

import Array
import Effect.Http
import Effect.Time
import Evergreen.V319.Go
import Evergreen.V319.Id
import Evergreen.V319.IdArray
import Evergreen.V319.NonemptyDict
import Evergreen.V319.OneOrGreater
import Evergreen.V319.Scroll
import Evergreen.V319.UserSession
import List.Nonempty
import SeqDict
import Set


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
    | PressedPlayerRow (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | MouseEnterPlayerRow (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | MouseExitPlayerRow (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | UserScrolledPastMoves Evergreen.V319.Scroll.ScrollPosition


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
    | ChangedPlaceWordAttempts Evergreen.V319.OneOrGreater.OneOrGreater
    | PressedResetLetters
    | PressedStartGame
    | PressedCancel
    | PressedLanguage Language
    | PressedExpandAdvancedSettings


type alias ValidatedSetup =
    { timeControls : Evergreen.V319.Go.TimeControl
    , traySize : Evergreen.V319.OneOrGreater.OneOrGreater
    , fullTrayBonus : Int
    , createdBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , seed : Int
    , letters :
        Evergreen.V319.NonemptyDict.NonemptyDict
            LetterOrWildcard
            { count : Evergreen.V319.OneOrGreater.OneOrGreater
            , value : Int
            }
    , language : Language
    , placeWordAttempts : Evergreen.V319.OneOrGreater.OneOrGreater
    }


type IsValid
    = IsValid
    | IsNotValid


type Action
    = PlaceWord PlacedWord (Evergreen.V319.UserSession.ToBeFilledInByBackend IsValid)
    | ReplaceTrayOrPass
    | JoinGame


type alias ActionWithTime =
    { userId : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type LetterId
    = LetterId Never


type alias Player =
    { userId : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , tray : Evergreen.V319.IdArray.IdArray LetterId LetterOrWildcard
    , score : Int
    }


type alias AnimatedPlacement =
    { startTime : Effect.Time.Posix
    , cells : List ( ( Int, Int ), LetterOrWildcard )
    , isValid : Evergreen.V319.UserSession.ToBeFilledInByBackend IsValid
    }


type alias Shared =
    { board : SeqDict.SeqDict ( Int, Int ) LetterOrWildcard
    , players : List.Nonempty.Nonempty Player
    , turnCount : Int
    , passingStartedAt : Maybe Int
    , lastPlacement : Maybe AnimatedPlacement
    , attemptsLeft : Evergreen.V319.OneOrGreater.OneOrGreater
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
    , highlightedPlayer : Maybe (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    , scrollPosition : Evergreen.V319.Scroll.ScrollPosition
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
    , placeWordAttempts : Evergreen.V319.OneOrGreater.OneOrGreater
    , advancedSettingsExpanded : Bool
    }


type WordList
    = WordList_NotLoaded
    | WordList_Loading
    | WordList_Error Effect.Http.Error
    | WordList_Loaded (Set.Set String)
