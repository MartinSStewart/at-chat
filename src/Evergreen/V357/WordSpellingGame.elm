module Evergreen.V357.WordSpellingGame exposing (..)

import Array
import Dict
import Effect.Http
import Effect.Time
import Evergreen.V357.Go
import Evergreen.V357.Id
import Evergreen.V357.IdArray
import Evergreen.V357.NonemptyDict
import Evergreen.V357.OneOrGreater
import Evergreen.V357.Scroll
import Evergreen.V357.UserSession
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
    | PressedPlayerRow (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | MouseEnterPlayerRow (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | MouseExitPlayerRow (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | MouseEnterWord (List ( ( Int, Int ), LetterOrWildcard ))
    | MouseExitWord
    | UserScrolledPastMoves Evergreen.V357.Scroll.ScrollPosition
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
    | ChangedPlaceWordAttempts Evergreen.V357.OneOrGreater.OneOrGreater
    | PressedResetLetters
    | PressedStartGame
    | PressedCancel
    | PressedLanguage Language
    | PressedExpandAdvancedSettings


type alias ValidatedSetup =
    { timeControls : Evergreen.V357.Go.TimeControl
    , traySize : Evergreen.V357.OneOrGreater.OneOrGreater
    , fullTrayBonus : Int
    , createdBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , seed : Int
    , letters :
        Evergreen.V357.NonemptyDict.NonemptyDict
            LetterOrWildcard
            { count : Evergreen.V357.OneOrGreater.OneOrGreater
            , value : Int
            }
    , language : Language
    , placeWordAttempts : Evergreen.V357.OneOrGreater.OneOrGreater
    }


type IsValid
    = IsValid (Set.Set String)
    | IsNotValid


type Action
    = PlaceWord PlacedWord (Evergreen.V357.UserSession.ToBeFilledInByBackend IsValid)
    | ReplaceTrayOrPass
    | JoinGame
    | Premove PlacedWord (Evergreen.V357.UserSession.ToBeFilledInByBackend IsValid)
    | CancelPremove


type alias ActionWithTime =
    { userId : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , time : Effect.Time.Posix
    , change : Action
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


type alias Player =
    { userId : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , tray : Evergreen.V357.IdArray.IdArray LetterId LetterOrWildcard
    , score : Int
    , premove : Maybe ( PlacedWord, PlacementResult, IsValid )
    }


type alias AnimatedPlacement =
    { startTime : Effect.Time.Posix
    , cells : List ( ( Int, Int ), LetterOrWildcard )
    , isValid : Evergreen.V357.UserSession.ToBeFilledInByBackend IsValid
    }


type alias Shared =
    { board : SeqDict.SeqDict ( Int, Int ) LetterOrWildcard
    , players : List.Nonempty.Nonempty Player
    , turnCount : Int
    , passingStartedAt : Maybe Int
    , lastPlacement : Maybe AnimatedPlacement
    , attemptsLeft : Evergreen.V357.OneOrGreater.OneOrGreater
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
    , highlightedPlayer : Maybe (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    , highlightedWordCells : Dict.Dict ( Int, Int ) LetterOrWildcard
    , scrollPosition : Evergreen.V357.Scroll.ScrollPosition
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
    , placeWordAttempts : Evergreen.V357.OneOrGreater.OneOrGreater
    , advancedSettingsExpanded : Bool
    }


type WordList
    = WordList_NotLoaded
    | WordList_Loading
    | WordList_Error Effect.Http.Error
    | WordList_Loaded (Set.Set String)
