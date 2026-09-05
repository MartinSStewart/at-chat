module Evergreen.V368.WordSpellingGame exposing (..)

import Array
import Dict
import Effect.Http
import Effect.Time
import Evergreen.V368.Go
import Evergreen.V368.Id
import Evergreen.V368.IdArray
import Evergreen.V368.NonemptyDict
import Evergreen.V368.OneOrGreater
import Evergreen.V368.Scroll
import Evergreen.V368.UserSession
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


type LetterId
    = LetterId Never


type alias PlacementResult =
    { words :
        List
            { letters : List LetterOrWildcard
            , placedCount : Int
            }
    , score : Int
    , placedCells : List ( ( Int, Int ), LetterOrWildcard )
    }


type IsValid
    = IsValid (Set.Set String)
    | IsNotValid


type alias Player =
    { userId : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , tray : Evergreen.V368.IdArray.IdArray LetterId LetterOrWildcard
    , score : Int
    , premove : Maybe ( PlacedWord, PlacementResult, IsValid )
    }


type alias AnimatedPlacement =
    { startTime : Effect.Time.Posix
    , cells : List ( ( Int, Int ), LetterOrWildcard )
    , isValid : Evergreen.V368.UserSession.ToBeFilledInByBackend IsValid
    }


type alias Shared =
    { board : SeqDict.SeqDict ( Int, Int ) LetterOrWildcard
    , players : List.Nonempty.Nonempty Player
    , turnCount : Int
    , passingStartedAt : Maybe Int
    , lastPlacement : Maybe AnimatedPlacement
    , attemptsLeft : Evergreen.V368.OneOrGreater.OneOrGreater
    }


type alias DictEntry =
    { partOfSpeech : String
    , definitions : List String
    }


type GameMsg
    = PressedSubmitWord PlacedWord
    | PressedJoinGame
    | PressedReplaceTrayOrPass
    | PressedClearBoard
    | PressedToggleSettings
    | PressedPlayerRow (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | MouseEnterPlayerRow (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | MouseExitPlayerRow (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | MouseEnterWord (List ( ( Int, Int ), LetterOrWildcard )) Shared
    | MouseExitWord
    | UserScrolledPastMoves Evergreen.V368.Scroll.ScrollPosition
    | PressedSubmitPremove PlacedWord
    | PressedWordDefinition (List.Nonempty.Nonempty String)
    | PressedPreviousWordDefinition
    | PressedNextWordDefinition
    | PressedCloseWordDefinition
    | GotWordDefinition String (Result Effect.Http.Error (List DictEntry))


type Language
    = English
    | Swedish


type SetupMsg
    = ChangedTraySizeInput String
    | ChangedFullTrayBonusInput String
    | ChangedLettersInput String
    | ChangedLetterValue Char String
    | ChangedPlaceWordAttempts Evergreen.V368.OneOrGreater.OneOrGreater
    | PressedResetLetters
    | PressedStartGame
    | PressedCancel
    | PressedLanguage Language
    | PressedExpandAdvancedSettings


type alias ValidatedSetup =
    { timeControls : Evergreen.V368.Go.TimeControl
    , traySize : Evergreen.V368.OneOrGreater.OneOrGreater
    , fullTrayBonus : Int
    , createdBy : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , seed : Int
    , letters :
        Evergreen.V368.NonemptyDict.NonemptyDict
            LetterOrWildcard
            { count : Evergreen.V368.OneOrGreater.OneOrGreater
            , value : Int
            }
    , language : Language
    , placeWordAttempts : Evergreen.V368.OneOrGreater.OneOrGreater
    }


type Action
    = PlaceWord PlacedWord (Evergreen.V368.UserSession.ToBeFilledInByBackend IsValid)
    | ReplaceTrayOrPass
    | JoinGame
    | Premove PlacedWord (Evergreen.V368.UserSession.ToBeFilledInByBackend IsValid)
    | CancelPremove


type alias ActionWithTime =
    { userId : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
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


type alias HoveredMove =
    { cells : Dict.Dict ( Int, Int ) LetterOrWildcard
    , shared : Shared
    }


type alias OpenWordDefinition =
    { words : List.Nonempty.Nonempty String
    , index : Int
    }


type WordDefinitionData
    = WordDefinition_Loading
    | WordDefinition_SwedishUnsupported
    | WordDefinition_NotFound
    | WordDefinition_Loaded (List DictEntry)


type WordDefinition
    = WordDefinition_None
    | WordDefinition_Open OpenWordDefinition WordDefinitionData


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
    , highlightedPlayer : Maybe (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    , hoveredMove : Maybe HoveredMove
    , scrollPosition : Evergreen.V368.Scroll.ScrollPosition
    , wordDefinition : WordDefinition
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
    , placeWordAttempts : Evergreen.V368.OneOrGreater.OneOrGreater
    , advancedSettingsExpanded : Bool
    }


type WordList
    = WordList_NotLoaded
    | WordList_Loading
    | WordList_Error Effect.Http.Error
    | WordList_Loaded (Set.Set String)
