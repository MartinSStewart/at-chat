module Evergreen.V326.WordSpellingGame exposing (..)

import Array
import Effect.Http
import Effect.Time
import Evergreen.V326.Go
import Evergreen.V326.Id
import Evergreen.V326.IdArray
import Evergreen.V326.NonemptyDict
import Evergreen.V326.OneOrGreater
import Evergreen.V326.Scroll
import Evergreen.V326.UserSession
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
    | PressedPlayerRow (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    | MouseEnterPlayerRow (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    | MouseExitPlayerRow (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    | UserScrolledPastMoves Evergreen.V326.Scroll.ScrollPosition


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
    | ChangedPlaceWordAttempts Evergreen.V326.OneOrGreater.OneOrGreater
    | PressedResetLetters
    | PressedStartGame
    | PressedCancel
    | PressedLanguage Language
    | PressedExpandAdvancedSettings


type alias ValidatedSetup =
    { timeControls : Evergreen.V326.Go.TimeControl
    , traySize : Evergreen.V326.OneOrGreater.OneOrGreater
    , fullTrayBonus : Int
    , createdBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , seed : Int
    , letters :
        Evergreen.V326.NonemptyDict.NonemptyDict
            LetterOrWildcard
            { count : Evergreen.V326.OneOrGreater.OneOrGreater
            , value : Int
            }
    , language : Language
    , placeWordAttempts : Evergreen.V326.OneOrGreater.OneOrGreater
    }


type IsValid
    = IsValid
    | IsNotValid


type Action
    = PlaceWord PlacedWord (Evergreen.V326.UserSession.ToBeFilledInByBackend IsValid)
    | ReplaceTrayOrPass
    | JoinGame


type alias ActionWithTime =
    { userId : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
    }


type LetterId
    = LetterId Never


type alias Player =
    { userId : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , tray : Evergreen.V326.IdArray.IdArray LetterId LetterOrWildcard
    , score : Int
    }


type alias AnimatedPlacement =
    { startTime : Effect.Time.Posix
    , cells : List ( ( Int, Int ), LetterOrWildcard )
    , isValid : Evergreen.V326.UserSession.ToBeFilledInByBackend IsValid
    }


type alias Shared =
    { board : SeqDict.SeqDict ( Int, Int ) LetterOrWildcard
    , players : List.Nonempty.Nonempty Player
    , turnCount : Int
    , passingStartedAt : Maybe Int
    , lastPlacement : Maybe AnimatedPlacement
    , attemptsLeft : Evergreen.V326.OneOrGreater.OneOrGreater
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
    , highlightedPlayer : Maybe (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    , scrollPosition : Evergreen.V326.Scroll.ScrollPosition
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
    , placeWordAttempts : Evergreen.V326.OneOrGreater.OneOrGreater
    , advancedSettingsExpanded : Bool
    }


type WordList
    = WordList_NotLoaded
    | WordList_Loading
    | WordList_Error Effect.Http.Error
    | WordList_Loaded (Set.Set String)
