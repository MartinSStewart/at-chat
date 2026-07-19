module WordSpellingGame exposing
    ( Action(..)
    , ActionWithTime
    , AnimatedPlacement
    , Description(..)
    , DictEntry
    , Drag(..)
    , GameData
    , GameMsg(..)
    , IsValid(..)
    , Language(..)
    , Letter(..)
    , LetterId
    , LetterOrWildcard(..)
    , LocalChange(..)
    , OpenWordDefinition
    , PlacedWord
    , PlacementResult
    , Player
    , SetupModel
    , SetupMsg(..)
    , SetupOrGame(..)
    , Shared
    , Tile
    , TilePosition(..)
    , TrayIndex(..)
    , UserStatus(..)
    , ValidatedSetup
    , WordDefinition(..)
    , WordDefinitionData(..)
    , WordList(..)
    , ZoomAnimation
    , ZoomState
    , animatedTilePlacement
    , anyTileAnimating
    , audio
    , boardTouchCoord
    , boardY
    , decodeDefinition
    , definitionApiUrl
    , dragEnd
    , dragStart
    , fullTrayBonusScore
    , gameView
    , initGame
    , initSetup
    , initShared
    , insideBoard
    , isAnimating
    , isZoomAnimating
    , nextTurnNotifications
    , parseWordList
    , pastWordsContainerId
    , placeWord
    , placementConnects
    , pressedKey
    , setupView
    , trayDropSlot
    , trayTouchCoord
    , updateAction
    , updateGame
    , updateSetup
    , validatePlacement
    , validateSetup
    )

{-| Were calling it this to avoid the Scrabble trademark
-}

import Array exposing (Array)
import Array.Extra
import Audio exposing (Audio)
import Char
import Color.Manipulate
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Dict
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom
import Effect.Http as Http
import Effect.Time as Time
import Email.Html
import Email.Html.Attributes
import Env
import Go exposing (TimeControl)
import Html
import Html.Attributes
import Html.Events
import Icons
import Id exposing (Id, UserId)
import IdArray exposing (IdArray)
import Json.Decode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptyExtra
import OneOrGreater exposing (OneOrGreater)
import PersonName
import Quantity
import Random
import Route exposing (Route)
import Scroll exposing (ScrollPosition(..))
import SeqDict exposing (SeqDict)
import SeqDictHelper
import Set exposing (Set)
import String.Nonempty exposing (NonemptyString(..))
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Accessibility
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Gradient
import Ui.Lazy
import Ui.Prose
import User exposing (LocalUser)
import UserSession exposing (ToBeFilledInByBackend(..))


{-| OpaqueVariants
-}
type Drag
    = Dragging Int
    | NotDragging


type alias GameData =
    { selectedCell : Maybe ( Int, Int )
    , tiles : Array Tile
    , dragging : Drag
    , zoomAnimation : ZoomAnimation
    , -- When a word placement arrived from the server (someone else's move, or ours from another
      -- device), along with how many letters it had. Drives the staggered pop sounds that match the
      -- word's slide-in animation (see `audio`); the local player's own moves pop via the tile
      -- times instead.
      lastWordPlaced : Maybe { time : Time.Posix, letterCount : Int }
    , showSettings : Bool
    , highlightedPlayer : Maybe (Id UserId)
    , scrollPosition : ScrollPosition
    , -- The dictionary definition popup opened by clicking a played word in the Moves log. Shown in
      -- a column to the right of the status view on wide screens, or overlaid on the board otherwise
      -- (see `gameView`).
      wordDefinition : WordDefinition
    }


{-| OpaqueVariants
-}
type WordDefinition
    = WordDefinition_None
    | WordDefinition_Open OpenWordDefinition WordDefinitionData


{-| The words an open definition popup can show: every dictionary word the clicked entry can stand
for (a placement with wildcards can have several, see `definitionWords`), and which of them is
currently shown. The header draws arrows to cycle through them when there's more than one.
-}
type alias OpenWordDefinition =
    { words : Nonempty String, index : Int }


currentDefinitionWord : OpenWordDefinition -> String
currentDefinitionWord open =
    List.Nonempty.get open.index open.words


{-| OpaqueVariants
-}
type WordDefinitionData
    = WordDefinition_Loading
      -- Swedish has no dictionary API wired up, so a clicked Swedish word just says so.
    | WordDefinition_SwedishUnsupported
      -- The lookup failed or the word wasn't in the dictionary (the API answers 404 for unknown
      -- words, which arrives here as an error).
    | WordDefinition_NotFound
    | WordDefinition_Loaded (List DictEntry)


{-| One part-of-speech grouping from a dictionary lookup, with its definitions in order.
-}
type alias DictEntry =
    { partOfSpeech : String
    , definitions : List String
    }


{-| The player's tiles, with any tile that was resting on a board cell another player's move has
since covered moved back into the tray. `GameData.tiles` isn't rewritten when a move arrives from
the server, so everything reading the tiles goes through this instead of using the raw array.

When the tray also shrank underneath the tiles (a premove of ours played out, consuming letters
without any local input), one covered tile per missing letter is removed outright instead of
returned, keeping the array index-aligned with the player's tray letters (see `placedTiles`).

-}
getTiles : Coord CssPixels -> Id UserId -> ValidatedSetup -> Shared -> Array Tile -> Array Tile
getTiles windowSize currentUserId setup shared tiles =
    let
        trayCount : Int
        trayCount =
            case getPlayer currentUserId shared of
                Just player ->
                    IdArray.length player.tray

                Nothing ->
                    Array.length tiles

        isCovered : Tile -> Bool
        isCovered tile =
            case tile.position of
                TileInTray _ _ ->
                    False

                TileOnBoard gridPos _ ->
                    SeqDict.member gridPos shared.board

        tiles2 : Array Tile
        tiles2 =
            Array.foldl
                (\tile ( toDrop, acc ) ->
                    if toDrop > 0 && isCovered tile then
                        ( toDrop - 1, acc )

                    else
                        ( toDrop, Array.push tile acc )
                )
                ( Array.length tiles - trayCount, Array.empty )
                tiles
                |> Tuple.second
    in
    List.foldl
        (\( index, tile ) tiles3 ->
            case tile.position of
                TileInTray _ _ ->
                    tiles3

                TileOnBoard gridPos time ->
                    case SeqDict.get gridPos shared.board of
                        Just _ ->
                            insertIntoTray time windowSize index Coord.origin setup tiles3

                        Nothing ->
                            tiles3
        )
        tiles2
        (Array.toIndexedList tiles2)


type alias ZoomAnimation =
    { start : Time.Posix, from : ZoomState }


type WordList
    = WordList_NotLoaded
    | WordList_Loading
    | WordList_Error Http.Error
    | WordList_Loaded (Set String)


type Language
    = English
    | Swedish


allLanguages : List Language
allLanguages =
    [ English
    , Swedish
    ]


languageToString : Language -> String
languageToString language =
    case language of
        English ->
            "English (NWL23)"

        Swedish ->
            "Swedish (SAOl13)"


{-| A resolution-independent description of the board zoom: `amount` runs 0 (no zoom, whole board
visible) to 1 (fully zoomed in), and `focusX`/`focusY` are the point the zoom centres on as a
fraction (0 to 1) of the board. Storing it this way (rather than in pixels) keeps it correct across
window resizes and lets the same value drive both the drawn board and touch hit-testing.
-}
type alias ZoomState =
    { amount : Float, focusX : Float, focusY : Float }


type alias Tile =
    { position : TilePosition, createdAt : Time.Posix }


{-| OpaqueVariants
-}
type TilePosition
    = -- The `Maybe ( Time.Posix, Int )` records, when the tile was shifted to make room for an
      -- inserted tile, the moment the shift started and the slot it shifted from, so the view can
      -- animate it sliding from its old slot to this one.
      TileInTray TrayIndex (Maybe ( Time.Posix, Int ))
    | TileOnBoard ( Int, Int ) Time.Posix


{-| Opaque
-}
type TrayIndex
    = TrayIndex Int


{-| OpaqueVariants
-}
type SetupMsg
    = ChangedTraySizeInput String
    | ChangedFullTrayBonusInput String
    | ChangedLettersInput String
    | ChangedLetterValue Char String
    | ChangedPlaceWordAttempts OneOrGreater
    | PressedResetLetters
    | PressedStartGame
    | PressedCancel
    | PressedLanguage Language
    | PressedExpandAdvancedSettings


type GameMsg
    = PressedSubmitWord PlacedWord
    | PressedJoinGame
    | PressedReplaceTrayOrPass
    | PressedClearBoard
    | PressedToggleSettings
    | PressedPlayerRow (Id UserId)
    | MouseEnterPlayerRow (Id UserId)
    | MouseExitPlayerRow (Id UserId)
    | UserScrolledPastMoves ScrollPosition
    | PressedSubmitPremove PlacedWord
    | PressedWordDefinition (Nonempty String)
    | PressedPreviousWordDefinition
    | PressedNextWordDefinition
    | PressedCloseWordDefinition
    | GotWordDefinition String (Result Http.Error (List DictEntry))


type alias SetupModel =
    { mainTimeInput : String
    , incrementInput : String
    , traySize : Int
    , fullTrayBonus : Int
    , error : Maybe String
    , letters : String

    -- The value input for each letter in the distribution, keyed by the letter's character.
    -- Letters without an entry fall back to `defaultLetterValue`.
    , letterValues : SeqDict Char String
    , language : Language
    , placeWordAttempts : OneOrGreater
    , advancedSettingsExpanded : Bool
    }


type alias ValidatedSetup =
    { timeControls : TimeControl
    , traySize : OneOrGreater
    , fullTrayBonus : Int
    , createdBy : Id UserId
    , seed : Int
    , letters : NonemptyDict LetterOrWildcard { count : OneOrGreater, value : Int }
    , language : Language
    , placeWordAttempts : OneOrGreater
    }


type Letter
    = LetterChar Char


initSetup : SetupModel
initSetup =
    { mainTimeInput = "10"
    , incrementInput = "5"
    , traySize = 7
    , fullTrayBonus = defaultFullTrayBonus
    , error = Nothing
    , letters = defaultLetters English
    , letterValues = SeqDict.empty
    , language = English
    , placeWordAttempts = OneOrGreater.three
    , advancedSettingsExpanded = False
    }


{-| The default points awarded for placing a word that uses every tile in a full tray (the
"bingo" bonus). Configurable per game in the setup view.
-}
defaultFullTrayBonus : number
defaultFullTrayBonus =
    50


pressedKey : GameData -> GameData
pressedKey model =
    model


initGame : Time.Posix -> Id UserId -> ValidatedSetup -> Shared -> GameData
initGame time currentUserId setup shared =
    let
        list =
            List.range 0 (OneOrGreater.toInt setup.traySize - 1)

        maybePlayer : Maybe Player
        maybePlayer =
            getPlayer currentUserId shared

        letters : IdArray LetterId LetterOrWildcard
        letters =
            case maybePlayer of
                Just player ->
                    player.tray

                Nothing ->
                    IdArray.empty
    in
    { selectedCell = Nothing
    , tiles =
        List.foldl
            (\index ( list2, premoveTiles ) ->
                let
                    createdAt =
                        Duration.addTo time (Duration.seconds (0.2 * toFloat index))

                    trayTile =
                        ( { position = TileInTray (TrayIndex index) Nothing
                          , createdAt = createdAt
                          }
                            :: list2
                        , premoveTiles
                        )
                in
                case IdArray.get (Id.fromInt index) letters of
                    Just letter ->
                        case List.Extra.findIndex (\( _, tile ) -> tile == letter) premoveTiles of
                            Just tileIndex ->
                                case List.Extra.getAt tileIndex premoveTiles of
                                    Just ( position, _ ) ->
                                        ( { position = TileOnBoard position createdAt
                                          , createdAt = createdAt
                                          }
                                            :: list2
                                        , List.Extra.removeAt tileIndex premoveTiles
                                        )

                                    Nothing ->
                                        trayTile

                            Nothing ->
                                trayTile

                    Nothing ->
                        trayTile
            )
            ( []
            , case maybePlayer of
                Just player ->
                    case player.premove of
                        Just ( _, result, _ ) ->
                            result.placedCells

                        Nothing ->
                            []

                Nothing ->
                    []
            )
            list
            |> Tuple.first
            |> List.reverse
            |> Array.fromList
    , dragging = NotDragging
    , zoomAnimation = { start = time, from = zoomedOutState }
    , lastWordPlaced = Nothing
    , showSettings = False
    , highlightedPlayer = Nothing
    , scrollPosition = ScrolledToBottom
    , wordDefinition = WordDefinition_None
    }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


type Action
    = PlaceWord PlacedWord (ToBeFilledInByBackend IsValid)
    | ReplaceTrayOrPass
    | JoinGame
    | Premove PlacedWord (ToBeFilledInByBackend IsValid)
    | CancelPremove


type IsValid
    = IsValid (Set String)
    | IsNotValid


type alias PlacedWord =
    { start : ( Int, Int )
    , isVertical : Bool
    , letters : Nonempty LetterOrWildcard
    }


type alias ActionWithTime =
    { userId : Id UserId, time : Time.Posix, change : Action }


type alias Shared =
    { board : SeqDict ( Int, Int ) LetterOrWildcard
    , players : Nonempty Player
    , turnCount : Int
    , passingStartedAt : Maybe Int
    , lastPlacement : Maybe AnimatedPlacement
    , attemptsLeft : OneOrGreater
    }


{-| The most recent placement, kept so the freshly placed tiles can be animated sliding onto the
board. This is derived from the action list (the start time comes from the `ActionWithTime`), so
the animated tiles themselves aren't tracked in the model; their on-screen positions are computed
purely from the current time (see `animatedTilePlacement`).
-}
type alias AnimatedPlacement =
    { startTime : Time.Posix
    , cells : List ( ( Int, Int ), LetterOrWildcard )
    , isValid : ToBeFilledInByBackend IsValid
    }


type alias Player =
    { userId : Id UserId
    , tray : IdArray LetterId LetterOrWildcard
    , score : Int
    , premove : Maybe ( PlacedWord, PlacementResult, IsValid )
    }


gridSize : number
gridSize =
    15


type LetterId
    = LetterId Never


type LetterOrWildcard
    = Letter Letter
    | Wildcard


initShared : ValidatedSetup -> Shared
initShared setup =
    let
        initialBoard : SeqDict ( Int, Int ) LetterOrWildcard
        initialBoard =
            SeqDict.empty
    in
    { board = initialBoard
    , players = Nonempty (initPlayer setup.createdBy initialBoard setup []) []
    , turnCount = 0
    , lastPlacement = Nothing
    , passingStartedAt = Nothing
    , attemptsLeft = setup.placeWordAttempts
    }


remainingLettersInBagCount : ValidatedSetup -> SeqDict ( Int, Int ) LetterOrWildcard -> List Player -> Int
remainingLettersInBagCount setup board players =
    SeqDict.foldl
        (\_ a total -> OneOrGreater.toInt a + total)
        0
        (remainingLettersInBag setup board players)


remainingLettersInBag :
    ValidatedSetup
    -> SeqDict ( Int, Int ) LetterOrWildcard
    -> List Player
    -> SeqDict LetterOrWildcard OneOrGreater
remainingLettersInBag setup board players =
    let
        remainingLetters : SeqDict LetterOrWildcard OneOrGreater
        remainingLetters =
            SeqDict.foldl
                (\_ letter startingLetters2 -> SeqDictHelper.decrement letter startingLetters2)
                (NonemptyDict.toSeqDict setup.letters |> SeqDict.map (\_ a -> a.count))
                board
    in
    List.foldl
        (\player remainingLetters2 -> IdArray.foldl SeqDictHelper.decrement remainingLetters2 player.tray)
        remainingLetters
        players


getLetters :
    OneOrGreater
    -> ValidatedSetup
    -> SeqDict ( Int, Int ) LetterOrWildcard
    -> List Player
    -> Int
    -> List LetterOrWildcard
getLetters count setup board players turnCount =
    Random.step
        (SeqDict.foldl
            (\letter count2 list -> List.repeat (OneOrGreater.toInt count2) letter ++ list)
            []
            (remainingLettersInBag setup board players)
            |> shuffle
        )
        (Random.initialSeed (setup.seed + turnCount))
        |> Tuple.first
        |> List.take (OneOrGreater.toInt count)


{-| Shuffle the list. Takes O(_n_ log _n_) time and no extra space. Original code found here <https://github.com/elm-community/random-extra/blob/d52055975644ad401709c2aff14dab9ca93e44a0/src/Random/List.elm#L88>
-}
shuffle : List a -> Random.Generator (List a)
shuffle list =
    Random.map
        (\independentSeed ->
            list
                |> List.foldl
                    (\item ( acc, seed ) ->
                        let
                            ( tag, nextSeed ) =
                                Random.step (Random.int Random.minInt Random.maxInt) seed
                        in
                        ( ( item, tag ) :: acc, nextSeed )
                    )
                    ( [], independentSeed )
                |> Tuple.first
                |> List.sortBy Tuple.second
                |> List.map Tuple.first
        )
        Random.independentSeed


type GameEndReason
    = EveryonePassed
    | OutOfLetters (Id UserId)


{-| Who to notify after an action was applied to the game, and with what content. If the action
ended the game every player is notified; otherwise only the player whose turn it now is gets a
notification, prefixed with what the previous player did (taken from the action's Moves log
entries). Nobody is notified for actions that don't move the turn along (joining, premoves, an
invalid move with attempts left).
-}
nextTurnNotifications :
    (Id UserId -> String)
    -> Route
    -> Shared
    -> List Description
    -> Shared
    -> List { userId : Id UserId, title : NonemptyString, pushNotificationText : String, emailText : String, emailHtml : Email.Html.Html }
nextTurnNotifications userToString route previousShared descriptions shared =
    let
        link : String
        link =
            Env.domain ++ Route.encode route

        previousActionsText : String
        previousActionsText =
            List.map
                (\description -> userToString (descriptionUserId description) ++ descriptionToString description)
                descriptions
                |> String.join ". "

        notificationFor :
            NonemptyString
            -> String
            -> Id UserId
            -> { userId : Id UserId, title : NonemptyString, pushNotificationText : String, emailText : String, emailHtml : Email.Html.Html }
        notificationFor title text userId =
            { userId = userId
            , title = title
            , pushNotificationText = text
            , emailText = text ++ "\n\nOpen " ++ link ++ " to view the game."
            , emailHtml = notificationEmailHtml text link shared
            }
    in
    case ( getWinner previousShared, getWinner shared ) of
        ( Just _, _ ) ->
            -- The game was already over before this action so there's nothing to notify about.
            []

        ( Nothing, Just ( winners, _ ) ) ->
            let
                winnerScore : Int
                winnerScore =
                    NonemptyExtra.maximumBy .score shared.players |> .score

                winnersText : String
                winnersText =
                    (case List.Nonempty.toList winners of
                        [ winner ] ->
                            userToString winner ++ " won with "

                        winners2 ->
                            String.join " and " (List.map userToString winners2) ++ " tied with "
                    )
                        ++ String.fromInt winnerScore
                        ++ " points!"
            in
            List.map
                (\player ->
                    notificationFor
                        (NonemptyString 'G' "ame over")
                        (addSentence previousActionsText ("The game has ended. " ++ winnersText))
                        player.userId
                )
                (List.Nonempty.toList shared.players)

        ( Nothing, Nothing ) ->
            if shared.turnCount == previousShared.turnCount then
                -- The turn didn't move on to another player so it's nobody's "your turn" moment.
                []

            else
                [ notificationFor
                    (NonemptyString 'Y' "our turn!")
                    (addSentence previousActionsText "It's your turn in the Word Spelling Game.")
                    (List.Nonempty.get shared.turnCount shared.players).userId
                ]


addSentence : String -> String -> String
addSentence first second =
    if first == "" then
        second

    else
        first ++ ". " ++ second


notificationEmailHtml : String -> String -> Shared -> Email.Html.Html
notificationEmailHtml text link shared =
    Email.Html.div
        [ Email.Html.Attributes.fontFamily "Arial, Helvetica, sans-serif" ]
        [ Email.Html.div
            [ Email.Html.Attributes.fontSize "15px"
            , Email.Html.Attributes.paddingBottom "12px"
            ]
            [ Email.Html.text text ]
        , emailBoardView shared
        , Email.Html.div
            [ Email.Html.Attributes.paddingTop "20px" ]
            [ Email.Html.b
                []
                [ Email.Html.a
                    [ Email.Html.Attributes.href link
                    , Email.Html.Attributes.backgroundColor (MyUi.colorToHex MyUi.buttonBackground)
                    , Email.Html.Attributes.color (MyUi.colorToHex MyUi.white)
                    , Email.Html.Attributes.fontSize "14px"
                    , Email.Html.Attributes.padding "4px 8px"
                    , Email.Html.Attributes.borderRadius "4px"
                    , Email.Html.Attributes.style "text-decoration" "none"
                    , Email.Html.Attributes.style "display" "inline-block"
                    ]
                    [ Email.Html.text "Open game" ]
                ]
            ]
        ]


{-| The board rendered as a plain table so it shows up in email clients, which only support a
small subset of CSS. The cells of the most recent placement use the same brighter gold as
freshly placed tiles in the app, so the notified player can see at a glance what just happened.
-}
emailBoardView : Shared -> Email.Html.Html
emailBoardView shared =
    let
        lastPlaced : Set ( Int, Int )
        lastPlaced =
            case shared.lastPlacement of
                Just placement ->
                    List.map Tuple.first placement.cells |> Set.fromList

                Nothing ->
                    Set.empty
    in
    Email.Html.table
        [ Email.Html.Attributes.attribute "cellspacing" "0"
        , Email.Html.Attributes.attribute "cellpadding" "0"
        , Email.Html.Attributes.style "border-collapse" "collapse"
        ]
        (List.map
            (\y ->
                Email.Html.tr
                    []
                    (List.map
                        (\x -> emailBoardCellView shared.board lastPlaced ( x, y ))
                        (List.range 0 (gridSize - 1))
                    )
            )
            (List.range 0 (gridSize - 1))
        )


emailBoardCellView : SeqDict ( Int, Int ) LetterOrWildcard -> Set ( Int, Int ) -> ( Int, Int ) -> Email.Html.Html
emailBoardCellView board lastPlaced position =
    let
        cell : List Email.Html.Attribute -> String -> Email.Html.Html
        cell attributes label =
            Email.Html.td
                ([ Email.Html.Attributes.width "22px"
                 , Email.Html.Attributes.height "22px"
                 , Email.Html.Attributes.textAlign "center"
                 , Email.Html.Attributes.border "1px solid #cccccc"
                 , Email.Html.Attributes.style "font-weight" "bold"
                 ]
                    ++ attributes
                )
                [ Email.Html.text label ]
    in
    case SeqDict.get position board of
        Just letterOrWildcard ->
            cell
                [ Email.Html.Attributes.backgroundColor
                    (if Set.member position lastPlaced then
                        -- Fresh tile gold (see tileInFront).
                        "#f0dc82"

                     else
                        -- Committed tile gold (see boardTileInFront).
                        "#baab67"
                    )
                , Email.Html.Attributes.color "#000000"
                , Email.Html.Attributes.fontSize "16px"
                ]
                (letterOrWildcardText letterOrWildcard)

        Nothing ->
            case SeqDict.get position bonusCells of
                Just bonus ->
                    cell
                        [ Email.Html.Attributes.backgroundColor (MyUi.colorToStyle (bonusCellColor bonus))
                        , Email.Html.Attributes.color
                            (bonusCellColor bonus |> Color.Manipulate.darken 0.3 |> MyUi.colorToStyle)
                        , Email.Html.Attributes.fontSize
                            (case bonus of
                                CenterCell ->
                                    "14px"

                                _ ->
                                    "9px"
                            )
                        ]
                        (bonusCellLabel bonus)

                Nothing ->
                    cell
                        [ Email.Html.Attributes.backgroundColor "#fafafa" ]
                        "\u{00A0}"


{-| The game is over either when every player has passed in turn, or as soon as any player has no
letters left. An empty tray means the bag is empty too: trays are refilled from the bag after every
placement, so a tray can only end up empty once there was nothing left to draw.
-}
getWinner : Shared -> Maybe ( Nonempty (Id UserId), GameEndReason )
getWinner shared =
    let
        everyonePassed : Bool
        everyonePassed =
            case shared.passingStartedAt of
                Just passingStartedAt ->
                    List.Nonempty.length shared.players <= shared.turnCount - passingStartedAt

                Nothing ->
                    False

        someoneOutOfLetters : Maybe Player
        someoneOutOfLetters =
            List.Extra.find (\player -> IdArray.isEmpty player.tray) (List.Nonempty.toList shared.players)

        getHighestScorers () =
            let
                player =
                    NonemptyExtra.maximumBy .score shared.players
            in
            List.Nonempty.filter (\a -> a.score == player.score) player shared.players |> List.Nonempty.map .userId
    in
    case someoneOutOfLetters of
        Just outOfLetters ->
            Just ( getHighestScorers (), OutOfLetters outOfLetters.userId )

        Nothing ->
            if everyonePassed then
                Just ( getHighestScorers (), EveryonePassed )

            else
                Nothing


{-| The extra points awarded for placing a word that empties a full tray in one move (a "bingo").
A placement can only draw from the player's tray, which never holds more than `traySize` tiles, so
placing exactly `traySize` letters means every tile of a full tray was used. Returns 0 otherwise.
-}
fullTrayBonusScore : ValidatedSetup -> PlacedWord -> Int
fullTrayBonusScore setup placedWord =
    if List.Nonempty.length placedWord.letters == OneOrGreater.toInt setup.traySize then
        setup.fullTrayBonus

    else
        0


handlePlaceWord :
    Time.Posix
    -> ValidatedSetup
    -> PlacedWord
    -> Bool
    -> ( SeqDict ( Int, Int ) LetterOrWildcard, PlacementResult )
    -> ToBeFilledInByBackend IsValid
    -> Player
    -> Shared
    -> ( Shared, List Description )
handlePlaceWord time setup placedWord isPremove ( board, result ) isValid player shared =
    let
        animatedPlacement : Maybe AnimatedPlacement
        animatedPlacement =
            Just { startTime = time, cells = result.placedCells, isValid = isValid }

        remainingTray : List LetterOrWildcard
        remainingTray =
            List.foldl
                removeFromTray
                (IdArray.toList player.tray)
                (List.Nonempty.toList placedWord.letters)

        tray : IdArray LetterId LetterOrWildcard
        tray =
            case isValid of
                FilledInByBackend IsNotValid ->
                    -- The placed letters return to the player's tray instead
                    -- of going back in the bag, and nothing new is drawn.
                    -- They're appended after the kept letters so they land in
                    -- the tray slots the placement freed up (the local tile
                    -- model refilled those slots on submit).
                    remainingTray
                        ++ List.Nonempty.toList placedWord.letters
                        |> IdArray.fromList

                _ ->
                    let
                        drawn : List LetterOrWildcard
                        drawn =
                            case OneOrGreater.fromInt (OneOrGreater.toInt setup.traySize - List.length remainingTray) of
                                Just drawCount ->
                                    getLetters
                                        drawCount
                                        setup
                                        board
                                        (NonemptyExtra.set shared.turnCount { player | tray = IdArray.fromList remainingTray } shared.players
                                            |> List.Nonempty.toList
                                        )
                                        shared.turnCount

                                Nothing ->
                                    []
                    in
                    remainingTray ++ drawn |> IdArray.fromList

        shared2 : Shared
        shared2 =
            { shared
                | board =
                    case isValid of
                        FilledInByBackend IsNotValid ->
                            shared.board

                        _ ->
                            board
                , players =
                    NonemptyExtra.set
                        shared.turnCount
                        { player
                            | tray = tray
                            , score =
                                case isValid of
                                    FilledInByBackend IsNotValid ->
                                        player.score

                                    _ ->
                                        player.score + result.score + fullTrayBonusScore setup placedWord
                        }
                        shared.players
                , lastPlacement = animatedPlacement
                , passingStartedAt =
                    if tray == IdArray.empty then
                        case shared.passingStartedAt of
                            Nothing ->
                                Just shared.turnCount

                            Just _ ->
                                shared.passingStartedAt

                    else
                        Nothing
            }
    in
    case isValid of
        FilledInByBackend IsNotValid ->
            case OneOrGreater.decrement shared2.attemptsLeft of
                Just attemptsLeft ->
                    ( { shared2 | attemptsLeft = attemptsLeft }
                    , [ Description_InvalidMove player.userId (Just attemptsLeft) ]
                    )

                Nothing ->
                    incrementTurnCount (Description_InvalidMove player.userId Nothing) time setup shared2

        FilledInByBackend (IsValid wildcardMatches) ->
            incrementTurnCount (placedWordDescription setup player placedWord result isPremove wildcardMatches) time setup shared2

        EmptyPlaceholder ->
            -- The move hasn't been validated by the backend yet, but it's described optimistically
            -- so the mover sees it in the log right away (mirrored by the board update above).
            ( shared2, [ placedWordDescription setup player placedWord result isPremove Set.empty ] )


placedWordDescription : ValidatedSetup -> Player -> PlacedWord -> PlacementResult -> Bool -> Set String -> Description
placedWordDescription setup player placedWord result isPremove wildcardMatches =
    let
        bonus : Int
        bonus =
            fullTrayBonusScore setup placedWord
    in
    Description_PlacedWord
        player.userId
        { word = headlineWord result.words
        , points = result.score + bonus
        , isBingo = bonus /= 0
        , placedCells = List.map Tuple.first result.placedCells
        , isPremove = isPremove
        , wildcardMatches = wildcardMatches
        }


{-| One entry of the Moves log, carrying who did it and everything the view needs to describe it
(see `descriptionView`). A single action can produce several entries: ending a turn can play out
the next player's premove (or fail to), which gets its own entry attributed to the premover.
-}
type Description
    = Description_PlacedWord (Id UserId) { word : String, points : Int, isBingo : Bool, placedCells : List ( Int, Int ), isPremove : Bool, wildcardMatches : Set String }
    | Description_InvalidMove (Id UserId) (Maybe OneOrGreater)
    | Description_ReplacedTray (Id UserId)
    | Description_Passed (Id UserId)
    | Description_EndedGame (Id UserId)
    | Description_Joined (Id UserId)
    | Description_PremoveBlocked (Id UserId)


updateAction : ValidatedSetup -> ActionWithTime -> Shared -> ( Shared, List Description )
updateAction setup action shared =
    case action.change of
        PlaceWord placedWord isValid ->
            case ( getWinner shared, getPlayer action.userId shared, isPlayerTurn action.userId shared ) of
                ( Nothing, Just player, JoinedAndItsTheirTurn ) ->
                    case placeWord setup shared.board placedWord of
                        Just result ->
                            handlePlaceWord action.time setup placedWord False result isValid player shared

                        Nothing ->
                            ( shared, [] )

                _ ->
                    ( shared, [] )

        ReplaceTrayOrPass ->
            case ( getWinner shared, getPlayer action.userId shared ) of
                ( Nothing, Just player ) ->
                    case passBehavior setup shared of
                        ShouldReplaceTray ->
                            { shared
                                | players =
                                    NonemptyExtra.set
                                        shared.turnCount
                                        { player
                                            | tray =
                                                getLetters
                                                    setup.traySize
                                                    setup
                                                    shared.board
                                                    (NonemptyExtra.set shared.turnCount { player | tray = IdArray.empty } shared.players
                                                        |> List.Nonempty.toList
                                                    )
                                                    (if shared.turnCount == 0 then
                                                        -- Clunky work around in order to not desync old games while fixing a bug where replacing a tray on turn 0 gives you back the same tray
                                                        9999

                                                     else
                                                        shared.turnCount
                                                    )
                                                    |> IdArray.fromList
                                        }
                                        shared.players
                                , passingStartedAt = Nothing
                            }
                                |> incrementTurnCount (Description_ReplacedTray action.userId) action.time setup

                        ShouldPass ->
                            { shared
                                | passingStartedAt =
                                    case shared.passingStartedAt of
                                        Nothing ->
                                            Just shared.turnCount

                                        Just _ ->
                                            shared.passingStartedAt
                            }
                                |> incrementTurnCount (Description_Passed action.userId) action.time setup

                        ShouldEndGame ->
                            incrementTurnCount (Description_EndedGame action.userId) action.time setup shared

                _ ->
                    ( shared, [] )

        JoinGame ->
            if canJoin shared then
                ( { shared
                    | players =
                        List.Nonempty.append
                            shared.players
                            (Nonempty
                                (initPlayer action.userId shared.board setup (List.Nonempty.toList shared.players))
                                []
                            )
                  }
                , [ Description_Joined action.userId ]
                )

            else
                ( shared, [] )

        Premove placedWord isValid ->
            case ( getWinner shared, isPlayerTurn action.userId shared, placeWord setup shared.board placedWord ) of
                ( Nothing, Joined, Just ( _, result ) ) ->
                    ( { shared
                        | players =
                            List.Nonempty.map
                                (\player ->
                                    if player.userId == action.userId then
                                        { player
                                            | premove =
                                                Just
                                                    ( placedWord
                                                    , result
                                                    , case isValid of
                                                        FilledInByBackend isValid2 ->
                                                            isValid2

                                                        EmptyPlaceholder ->
                                                            IsNotValid
                                                    )
                                        }

                                    else
                                        player
                                )
                                shared.players
                      }
                    , []
                    )

                _ ->
                    ( shared, [] )

        CancelPremove ->
            ( { shared
                | players =
                    List.Nonempty.map
                        (\player ->
                            if player.userId == action.userId then
                                { player | premove = Nothing }

                            else
                                player
                        )
                        shared.players
              }
            , []
            )


incrementTurnCount : Description -> Time.Posix -> ValidatedSetup -> Shared -> ( Shared, List Description )
incrementTurnCount description time setup shared =
    let
        turnCount =
            shared.turnCount + 1

        nextPlayer =
            List.Nonempty.get turnCount shared.players

        nextPlayerNoPremove =
            { nextPlayer | premove = Nothing }

        shared2 =
            { shared
                | turnCount = turnCount
                , attemptsLeft = setup.placeWordAttempts
                , players = NonemptyExtra.set turnCount nextPlayerNoPremove shared.players
            }
    in
    case nextPlayer.premove of
        Just ( premove, expected, isValid ) ->
            case placeWord setup shared2.board premove of
                Just ( board, result ) ->
                    if result == expected then
                        handlePlaceWord
                            time
                            setup
                            premove
                            True
                            ( board, result )
                            (FilledInByBackend isValid)
                            nextPlayerNoPremove
                            shared2
                            |> Tuple.mapSecond (\a -> description :: a)

                    else
                        ( shared2
                        , [ description, Description_PremoveBlocked nextPlayer.userId ]
                        )

                Nothing ->
                    ( shared2
                    , [ description, Description_PremoveBlocked nextPlayer.userId ]
                    )

        Nothing ->
            ( shared2, [ description ] )


canJoin : Shared -> Bool
canJoin shared =
    shared.turnCount <= List.Nonempty.length shared.players


initPlayer : Id UserId -> SeqDict ( Int, Int ) LetterOrWildcard -> ValidatedSetup -> List Player -> Player
initPlayer userId board setup existingPlayers =
    { userId = userId
    , tray = getLetters setup.traySize setup board existingPlayers 0 |> IdArray.fromList
    , score = 0
    , premove = Nothing
    }


type alias PlacementResult =
    { words : List { letters : List LetterOrWildcard, placedCount : Int }
    , score : Int
    , placedCells : List ( ( Int, Int ), LetterOrWildcard )
    }


{-| Lay a word's new letters out along the placement direction starting from `start`, stepping
over any tiles already on the board (which aren't placed again), then work out every word that
the placement forms: the main word along the placement direction, plus any perpendicular
cross-word that runs through a newly-placed tile. Returns `Nothing` if the letters run off the
edge of the board.

The returned `words` are the formed words' tiles in order (upper case, like the word list), and
`score` is the combined Scrabble score of all the formed words (letter and word multipliers only
apply to the squares the new tiles land on; wildcards score zero).

-}
placeWord : ValidatedSetup -> SeqDict ( Int, Int ) LetterOrWildcard -> PlacedWord -> Maybe ( SeqDict ( Int, Int ) LetterOrWildcard, PlacementResult )
placeWord setup board placedWord =
    let
        ( dx, dy ) =
            if placedWord.isVertical then
                ( 0, 1 )

            else
                ( 1, 0 )

        -- Lay out the new tiles, stepping over tiles already committed to the board.
        layout : ( Int, Int ) -> List LetterOrWildcard -> List ( ( Int, Int ), LetterOrWildcard ) -> Maybe (List ( ( Int, Int ), LetterOrWildcard ))
        layout ( cx, cy ) remaining acc =
            case remaining of
                [] ->
                    Just (List.reverse acc)

                letterOrWildcard :: rest ->
                    if cx < 0 || cy < 0 || cx >= gridSize || cy >= gridSize then
                        Nothing

                    else
                        case SeqDict.get ( cx, cy ) board of
                            Just _ ->
                                layout ( cx + dx, cy + dy ) remaining acc

                            Nothing ->
                                layout ( cx + dx, cy + dy ) rest (( ( cx, cy ), letterOrWildcard ) :: acc)
    in
    case layout placedWord.start (List.Nonempty.toList placedWord.letters) [] of
        Just placedCells ->
            let
                newBoard : SeqDict ( Int, Int ) LetterOrWildcard
                newBoard =
                    List.foldl
                        (\( cell, letterOrWildcard ) acc -> SeqDict.insert cell letterOrWildcard acc)
                        board
                        placedCells

                placedCoords : List ( Int, Int )
                placedCoords =
                    List.map Tuple.first placedCells

                placedSet : Set ( Int, Int )
                placedSet =
                    Set.fromList placedCoords

                -- The main word runs along the placement direction through the first placed tile.
                mainWord : List ( Int, Int )
                mainWord =
                    case placedCoords of
                        first :: _ ->
                            lineWord newBoard ( dx, dy ) first

                        [] ->
                            []

                -- A cross word runs perpendicular to the placement direction through a placed tile.
                crossWords : List (List ( Int, Int ))
                crossWords =
                    List.filterMap
                        (\cell ->
                            let
                                word : List ( Int, Int )
                                word =
                                    lineWord newBoard ( dy, dx ) cell
                            in
                            if List.length word >= 2 then
                                Just word

                            else
                                Nothing
                        )
                        placedCoords

                allWords : List (List ( Int, Int ))
                allWords =
                    (if List.length mainWord >= 2 then
                        [ mainWord ]

                     else
                        []
                    )
                        ++ crossWords
            in
            ( newBoard
            , { words =
                    List.map
                        (\wordCoords ->
                            { letters = wordString newBoard wordCoords
                            , placedCount = List.Extra.count (\cell -> Set.member cell placedSet) wordCoords
                            }
                        )
                        allWords
              , score = List.sum (List.map (wordScore setup newBoard placedSet) allWords)
              , placedCells = placedCells
              }
            )
                |> Just

        Nothing ->
            Nothing


{-| The maximal contiguous run of tiles through `cell` in the direction `( dirX, dirY )`.
-}
lineWord : SeqDict ( Int, Int ) LetterOrWildcard -> ( Int, Int ) -> ( Int, Int ) -> List ( Int, Int )
lineWord board ( dirX, dirY ) cell =
    let
        walkBack : ( Int, Int ) -> ( Int, Int )
        walkBack ( cx, cy ) =
            let
                prev : ( Int, Int )
                prev =
                    ( cx - dirX, cy - dirY )
            in
            if SeqDict.member prev board then
                walkBack prev

            else
                ( cx, cy )

        walkForward : ( Int, Int ) -> List ( Int, Int ) -> List ( Int, Int )
        walkForward ( cx, cy ) acc =
            if SeqDict.member ( cx, cy ) board then
                walkForward ( cx + dirX, cy + dirY ) (( cx, cy ) :: acc)

            else
                List.reverse acc
    in
    walkForward (walkBack cell) []


{-| The tiles (letters and wildcards) forming the word at the given cells, in order. Wildcards are
kept as `Wildcard` rather than resolved to a letter, since the tile on the board doesn't record
which letter the player meant; `bruteForceMatch` tries every letter for them when checking the word.
-}
wordString : SeqDict ( Int, Int ) LetterOrWildcard -> List ( Int, Int ) -> List LetterOrWildcard
wordString board cells =
    List.filterMap (\cell -> SeqDict.get cell board) cells


{-| The Scrabble score of a single word. Letter and word multipliers only apply to the squares
that the newly-placed tiles (`placedSet`) land on; wildcards always score zero.
-}
wordScore : ValidatedSetup -> SeqDict ( Int, Int ) LetterOrWildcard -> Set ( Int, Int ) -> List ( Int, Int ) -> Int
wordScore setup board placedSet cells =
    let
        letterSum : Int
        letterSum =
            List.map
                (\cell ->
                    case SeqDict.get cell board of
                        Just (Letter letter) ->
                            if Set.member cell placedSet then
                                letterValue setup letter * letterScoreMultiplier cell

                            else
                                letterValue setup letter

                        Just Wildcard ->
                            0

                        Nothing ->
                            0
                )
                cells
                |> List.sum

        wordMultiplier : Int
        wordMultiplier =
            List.map
                (\cell ->
                    if Set.member cell placedSet then
                        wordScoreMultiplier cell

                    else
                        1
                )
                cells
                |> List.product
    in
    letterSum * wordMultiplier


{-| Check that every word a placement forms is in the word list. Alongside the placement result,
a successful validation returns the headline word's valid wildcard fill-ins (see
`bruteForceMatch`), which travel back to the clients inside `IsValid` so the Moves log can resolve
the wildcards when looking up the word's dictionary definition.
-}
validatePlacement : Set String -> ValidatedSetup -> SeqDict ( Int, Int ) LetterOrWildcard -> PlacedWord -> Result () ( PlacementResult, Set String )
validatePlacement dictionary setup board placedWord =
    case placeWord setup board placedWord of
        Just ( _, result ) ->
            let
                wordMatches : List ( { letters : List LetterOrWildcard, placedCount : Int }, Set String )
                wordMatches =
                    List.map
                        (\word ->
                            ( word
                            , -- We don't allow words with more than two wildcards for performance/RAM reasons
                              if List.Extra.count (\cell -> cell == Wildcard) word.letters <= wildcardMax then
                                bruteForceMatch (wildcardCandidateLetters setup) dictionary word.letters

                              else
                                Set.empty
                            )
                        )
                        result.words
            in
            if List.isEmpty result.words then
                Err ()

            else if List.all (\( _, matches ) -> not (Set.isEmpty matches)) wordMatches then
                ( result
                , List.sortBy (\( word, _ ) -> headlineOrder word) wordMatches
                    |> List.head
                    |> Maybe.map Tuple.second
                    |> Maybe.withDefault Set.empty
                )
                    |> Ok

            else
                Err ()

        Nothing ->
            Err ()


{-| The letters a wildcard (blank tile) may stand for. A blank isn't limited to the letters that
happen to be in the bag: like a real Scrabble blank it can be any letter of the game's alphabet, so
e.g. "\_\_C" validates as "ARC" even when A and R were removed from the distribution. Any extra
letters a custom distribution introduced are included too, so those tiles remain reachable.
-}
wildcardCandidateLetters : ValidatedSetup -> List Letter
wildcardCandidateLetters setup =
    List.filterMap
        (\letterOrWildcard ->
            case letterOrWildcard of
                Letter (LetterChar char) ->
                    Just char

                Wildcard ->
                    Nothing
        )
        (NonemptyDict.keys setup.letters |> List.Nonempty.toList)
        |> List.foldl Set.insert (alphabet setup.language)
        |> Set.toList
        |> List.map LetterChar


{-| The letters of a language's alphabet, matching the letters used by its word list. These are the
letters a blank tile can stand for, regardless of which tiles the game's distribution includes.
-}
alphabet : Language -> Set Char
alphabet language =
    (case language of
        English ->
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        Swedish ->
            "ABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ"
    )
        |> String.toList
        |> Set.fromList


{-| Try every letter for each wildcard, building the candidate string from left to right, and
collect every way of filling in the wildcards (in order) that lands on a word in the word list:
H\_P returns a set with "O", "I", etc, and \_OL\_ returns a set with "BT", "DT", etc. An empty set
means no fill-in works, i.e. the word is invalid; a valid word with no wildcards returns a set
holding just the empty string. Only used when there are few wildcards (see `wildcardMax`), so this
does at most n^k lookups for small `k`.
-}
bruteForceMatch : List Letter -> Set String -> List LetterOrWildcard -> Set String
bruteForceMatch candidateLetters wordList word =
    let
        search : List LetterOrWildcard -> String -> String -> Set String -> Set String
        search remaining prefix wildcardLetters matches =
            case remaining of
                [] ->
                    if Set.member prefix wordList then
                        Set.insert wildcardLetters matches

                    else
                        matches

                (Letter (LetterChar letter)) :: rest ->
                    search rest (prefix ++ String.fromChar letter) wildcardLetters matches

                Wildcard :: rest ->
                    List.foldl
                        (\(LetterChar letter) matches2 ->
                            search
                                rest
                                (prefix ++ String.fromChar letter)
                                (wildcardLetters ++ String.fromChar letter)
                                matches2
                        )
                        matches
                        candidateLetters
    in
    search word "" "" Set.empty


letterScoreMultiplier : ( Int, Int ) -> Int
letterScoreMultiplier position =
    case SeqDict.get position bonusCells of
        Just DoubleLetter ->
            2

        Just TripleLetter ->
            3

        _ ->
            1


wordScoreMultiplier : ( Int, Int ) -> Int
wordScoreMultiplier position =
    case SeqDict.get position bonusCells of
        Just DoubleWord ->
            2

        Just TripleWord ->
            3

        Just CenterCell ->
            2

        _ ->
            1


{-| Remove one matching tile from the tray. If the exact letter isn't held a wildcard must have
been used in its place, so remove a wildcard instead.
-}
removeFromTray : LetterOrWildcard -> List LetterOrWildcard -> List LetterOrWildcard
removeFromTray letterOrWildcard tray =
    if List.member letterOrWildcard tray then
        List.Extra.remove letterOrWildcard tray

    else
        List.Extra.remove Wildcard tray


type SetupOrGame
    = Setup SetupModel
    | Game GameData
    | CancelSetup


updateSetup :
    Time.Posix
    -> Id UserId
    -> SetupMsg
    -> SetupModel
    -> ( SetupOrGame, Maybe ValidatedSetup )
updateSetup time currentUserId msg setup =
    case msg of
        ChangedTraySizeInput input ->
            ( { setup
                | traySize = String.toInt (String.trim input) |> Maybe.withDefault setup.traySize
                , error = Nothing
              }
                |> Setup
            , Nothing
            )

        ChangedFullTrayBonusInput input ->
            ( { setup
                | fullTrayBonus = String.toInt (String.trim input) |> Maybe.withDefault setup.fullTrayBonus
                , error = Nothing
              }
                |> Setup
            , Nothing
            )

        ChangedLettersInput input ->
            ( Setup { setup | letters = input, error = Nothing }, Nothing )

        ChangedLetterValue char input ->
            ( Setup { setup | letterValues = SeqDict.insert char input setup.letterValues, error = Nothing }
            , Nothing
            )

        ChangedPlaceWordAttempts attempts ->
            ( Setup { setup | placeWordAttempts = attempts }, Nothing )

        PressedResetLetters ->
            ( Setup { setup | letters = defaultLetters setup.language, letterValues = SeqDict.empty, error = Nothing }
            , Nothing
            )

        PressedStartGame ->
            case validateSetup currentUserId time setup of
                Ok validated ->
                    ( initGame time currentUserId validated (initShared validated) |> Game
                    , Just validated
                    )

                Err error ->
                    ( Setup { setup | error = Just error }, Nothing )

        PressedCancel ->
            ( CancelSetup, Nothing )

        PressedLanguage language ->
            ( Setup { setup | language = language, letters = defaultLetters language }
            , Nothing
            )

        PressedExpandAdvancedSettings ->
            ( Setup { setup | advancedSettingsExpanded = not setup.advancedSettingsExpanded }
            , Nothing
            )


{-| Updates a game in response to a `GameMsg`. Alongside the new state it returns any `Action` to
broadcast to the other players, and a `Maybe String` naming an English word whose dictionary
definition the frontend should go fetch (see `Frontend.handleGameOutMsgs`).
-}
updateGame :
    Time.Posix
    -> Coord CssPixels
    -> Id UserId
    -> ValidatedSetup
    -> Shared
    -> GameMsg
    -> GameData
    -> ( GameData, Maybe Action, Maybe String )
updateGame time windowSize currentUserId setup shared msg oldModel =
    let
        -- Tiles that another player's move covered belong back in the tray; work off (and store)
        -- that corrected state so it can't disagree with what the view is showing.
        model : GameData
        model =
            { oldModel | tiles = getTiles windowSize currentUserId setup shared oldModel.tiles }
    in
    case msg of
        PressedSubmitWord placement ->
            case placeWord setup shared.board placement of
                Just ( _, result ) ->
                    let
                        -- The board cells this line actually consumes (its newly placed tiles).
                        lineCells : Set ( Int, Int )
                        lineCells =
                            List.map Tuple.first result.placedCells |> Set.fromList

                        -- Keep the tiles still in the tray as-is, and send any tiles the player left
                        -- on the board that aren't part of this line (stray letters) back to the
                        -- tray. The line's own tiles are consumed and replaced by freshly drawn ones.
                        kept : Array Tile
                        kept =
                            Array.foldl
                                (\tile acc ->
                                    case tile.position of
                                        TileInTray _ _ ->
                                            Array.push tile acc

                                        TileOnBoard cell _ ->
                                            if Set.member cell lineCells then
                                                acc

                                            else
                                                Array.push
                                                    { tile | position = TileInTray (firstOpenTrayIndex Nothing acc) Nothing }
                                                    acc
                                )
                                Array.empty
                                model.tiles

                        newTileCount : Int
                        newTileCount =
                            OneOrGreater.toInt setup.traySize - Array.length kept
                    in
                    ( withZoomAnimation time
                        model
                        { model
                            | dragging = NotDragging
                            , tiles =
                                List.foldl
                                    (\index tray ->
                                        Array.push
                                            { position = TileInTray (firstOpenTrayIndex Nothing tray) Nothing
                                            , createdAt =
                                                Duration.addTo
                                                    time
                                                    (Quantity.sum
                                                        [ Duration.seconds (0.1 * toFloat index)
                                                        , placementAnimationDuration (FilledInByBackend IsNotValid) newTileCount
                                                        ]
                                                    )
                                            }
                                            tray
                                    )
                                    kept
                                    (List.range 0 (newTileCount - 1))
                        }
                    , Just (PlaceWord placement EmptyPlaceholder)
                    , Nothing
                    )

                Nothing ->
                    ( model, Nothing, Nothing )

        PressedJoinGame ->
            ( model, Just JoinGame, Nothing )

        PressedReplaceTrayOrPass ->
            let
                lettersLeftIncludingTray =
                    remainingLettersInBagCount
                        setup
                        shared.board
                        (List.Nonempty.toList shared.players
                            |> List.filter (\player -> player.userId == currentUserId)
                        )
                        |> min (OneOrGreater.toInt setup.traySize)

                list =
                    List.range 0 (lettersLeftIncludingTray - 1)
            in
            ( { model
                | tiles =
                    List.map
                        (\index ->
                            { position = TileInTray (TrayIndex index) Nothing
                            , createdAt = Duration.addTo time (Duration.seconds (0.2 * toFloat index))
                            }
                        )
                        list
                        |> Array.fromList
              }
            , Just ReplaceTrayOrPass
            , Nothing
            )

        PressedClearBoard ->
            -- Send every tile the player has resting on the board back to the tray, keeping the tiles
            -- already in the tray where they are and filling the freed slots (mirrors how `dragEnd`
            -- returns a single tile). The order of `model.tiles` is preserved since it's index-aligned
            -- with the player's tray letters (see `placedTiles`).
            ( { model
                | dragging = NotDragging
                , tiles =
                    Array.foldl
                        (\tile ( acc, taken ) ->
                            case tile.position of
                                TileInTray _ _ ->
                                    ( Array.push tile acc, taken )

                                TileOnBoard _ _ ->
                                    let
                                        index : Int
                                        index =
                                            lowestFreeTrayIndex 0 taken
                                    in
                                    ( Array.push { tile | position = TileInTray (TrayIndex index) Nothing } acc
                                    , Set.insert index taken
                                    )
                        )
                        ( Array.empty, trayIndicesInUse model.tiles )
                        model.tiles
                        |> Tuple.first
              }
            , case getPlayer currentUserId shared of
                Just player ->
                    case player.premove of
                        Just _ ->
                            Just CancelPremove

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing
            , Nothing
            )

        PressedToggleSettings ->
            ( { model | showSettings = not model.showSettings }, Nothing, Nothing )

        PressedPlayerRow userId ->
            ( if MyUi.isMobileAlt windowSize then
                { model
                    | highlightedPlayer =
                        if model.highlightedPlayer == Just userId then
                            Nothing

                        else
                            Just userId
                }

              else
                model
            , Nothing
            , Nothing
            )

        MouseEnterPlayerRow userId ->
            ( { model | highlightedPlayer = Just userId }, Nothing, Nothing )

        MouseExitPlayerRow userId ->
            ( { model
                | highlightedPlayer =
                    if model.highlightedPlayer == Just userId then
                        Nothing

                    else
                        model.highlightedPlayer
              }
            , Nothing
            , Nothing
            )

        UserScrolledPastMoves position ->
            -- Track how far the Past moves list is scrolled so new moves only auto-scroll to the
            -- bottom when the player was already there (mirrors the conversation view; the scroll
            -- command itself is issued from Frontend).
            ( { model | scrollPosition = position }, Nothing, Nothing )

        PressedSubmitPremove placement ->
            case placeWord setup shared.board placement of
                Just _ ->
                    ( model, Just (Premove placement EmptyPlaceholder), Nothing )

                Nothing ->
                    ( model, Nothing, Nothing )

        PressedWordDefinition words ->
            openWordDefinition { words = words, index = 0 } setup model

        PressedPreviousWordDefinition ->
            cycleWordDefinition -1 setup model

        PressedNextWordDefinition ->
            cycleWordDefinition 1 setup model

        PressedCloseWordDefinition ->
            ( { model | wordDefinition = WordDefinition_None }, Nothing, Nothing )

        GotWordDefinition word result ->
            -- Only apply the response if the popup is still waiting on this exact word, so a slow
            -- reply for a word the player has since closed or replaced (or cycled away from) can't
            -- clobber the popup.
            ( case model.wordDefinition of
                WordDefinition_Open open WordDefinition_Loading ->
                    if currentDefinitionWord open == word then
                        { model | wordDefinition = WordDefinition_Open open (definitionResultToData result) }

                    else
                        model

                _ ->
                    model
            , Nothing
            , Nothing
            )


{-| Show the definition popup for one of `open`'s candidate words: show a loading popup and ask
the frontend to fetch the definition (the third tuple element). Swedish has no dictionary API
wired up, so there the popup just says so.
-}
openWordDefinition : OpenWordDefinition -> ValidatedSetup -> GameData -> ( GameData, Maybe Action, Maybe String )
openWordDefinition open setup model =
    case setup.language of
        English ->
            ( { model | wordDefinition = WordDefinition_Open open WordDefinition_Loading }
            , Nothing
            , Just (currentDefinitionWord open)
            )

        Swedish ->
            ( { model | wordDefinition = WordDefinition_Open open WordDefinition_SwedishUnsupported }
            , Nothing
            , Nothing
            )


{-| Step the open definition popup to the previous (-1) or next (1) candidate word, wrapping
around at both ends, and kick off the lookup of the newly shown word.
-}
cycleWordDefinition : Int -> ValidatedSetup -> GameData -> ( GameData, Maybe Action, Maybe String )
cycleWordDefinition offset setup model =
    case model.wordDefinition of
        WordDefinition_Open open _ ->
            openWordDefinition
                { open | index = modBy (List.Nonempty.length open.words) (open.index + offset) }
                setup
                model

        WordDefinition_None ->
            ( model, Nothing, Nothing )


{-| The tiles the local player has dragged onto the board this turn, paired with the letter each
holds (their tray is index-aligned with `GameData.tiles`; see `boardView`).
-}
placedTiles : Id UserId -> Shared -> GameData -> List ( ( Int, Int ), LetterOrWildcard )
placedTiles currentUserId shared model =
    case getPlayer currentUserId shared of
        Just player ->
            List.map2 Tuple.pair (Array.toList model.tiles) (IdArray.toList player.tray)
                |> List.filterMap
                    (\( tile, letter ) ->
                        case tile.position of
                            TileOnBoard cell _ ->
                                Just ( cell, letter )

                            TileInTray _ _ ->
                                Nothing
                    )

        Nothing ->
            []


{-| Every word the player could submit from the tiles they've placed on the board this turn. Each
straight run of the player's placed tiles (two or more collinear tiles, bridged by any committed
tiles between them, or a lone tile that extends an existing word) that forms a valid placement
becomes one entry, along with the board cell next to which its submit button is drawn.

A player can end up with several placed runs at once (e.g. tiles that cross, or a stray tile left
elsewhere); each valid run gets its own button, and submitting one returns the other placed tiles to
the tray (see `updateGame`). Whether the formed words are real dictionary words is still decided on
the backend (see `bruteForceMatch`).

-}
submittableLines : Id UserId -> Shared -> GameData -> List { placedWord : PlacedWord, buttonCell : ( Int, Int ) }
submittableLines currentUserId shared model =
    let
        placed : List ( ( Int, Int ), LetterOrWildcard )
        placed =
            placedTiles currentUserId shared model

        placedCells : Set ( Int, Int )
        placedCells =
            List.map Tuple.first placed |> Set.fromList

        runsFor : Bool -> List ( Bool, List ( ( Int, Int ), LetterOrWildcard ) )
        runsFor isVertical =
            lineRuns isVertical shared.board placed
                |> List.filter (\run -> List.length run >= 2)
                |> List.map (\run -> ( isVertical, run ))

        bigRuns : List ( Bool, List ( ( Int, Int ), LetterOrWildcard ) )
        bigRuns =
            runsFor False ++ runsFor True

        inBigRun : Set ( Int, Int )
        inBigRun =
            List.concatMap (\( _, run ) -> List.map Tuple.first run) bigRuns |> Set.fromList

        -- A placed tile that isn't part of any two-tile run is on its own; it can still be a valid
        -- play if it extends a committed word.
        loneRuns : List ( Bool, List ( ( Int, Int ), LetterOrWildcard ) )
        loneRuns =
            placed
                |> List.filter (\( cell, _ ) -> not (Set.member cell inBigRun))
                |> List.map (\tile -> ( False, [ tile ] ))
    in
    (bigRuns ++ loneRuns)
        |> List.filterMap
            (\( isVertical, run ) ->
                case buildPlacedWord isVertical shared run of
                    Ok placedWord ->
                        Just
                            { placedWord = placedWord
                            , buttonCell = submitButtonCell isVertical (List.map Tuple.first run) placedCells shared.board
                            }

                    Err () ->
                        Nothing
            )


{-| Split the placed tiles into maximal straight runs along one axis. Two placed tiles are in the
same run when they share the line (same row for horizontal, same column for vertical) and every cell
between them is filled, either by another placed tile or a committed one.
-}
lineRuns : Bool -> SeqDict ( Int, Int ) LetterOrWildcard -> List ( ( Int, Int ), LetterOrWildcard ) -> List (List ( ( Int, Int ), LetterOrWildcard ))
lineRuns isVertical board placed =
    let
        lineKey : ( Int, Int ) -> Int
        lineKey ( x, y ) =
            if isVertical then
                x

            else
                y

        linePos : ( Int, Int ) -> Int
        linePos ( x, y ) =
            if isVertical then
                y

            else
                x

        cellAt : Int -> Int -> ( Int, Int )
        cellAt key pos =
            if isVertical then
                ( key, pos )

            else
                ( pos, key )

        bridged : Int -> Int -> Int -> Bool
        bridged key from to =
            List.range (from + 1) (to - 1)
                |> List.all (\pos -> SeqDict.member (cellAt key pos) board)

        groups : List (List ( ( Int, Int ), LetterOrWildcard ))
        groups =
            List.foldr
                (\item dict -> Dict.update (lineKey (Tuple.first item)) (\m -> Just (item :: Maybe.withDefault [] m)) dict)
                Dict.empty
                placed
                |> Dict.values
    in
    List.concatMap
        (\group ->
            let
                key : Int
                key =
                    case group of
                        ( cell, _ ) :: _ ->
                            lineKey cell

                        [] ->
                            0

                sorted : List ( ( Int, Int ), LetterOrWildcard )
                sorted =
                    List.sortBy (\( cell, _ ) -> linePos cell) group
            in
            List.foldl
                (\item runs ->
                    case runs of
                        currentRun :: doneRuns ->
                            case currentRun of
                                ( lastCell, _ ) :: _ ->
                                    if bridged key (linePos lastCell) (linePos (Tuple.first item)) then
                                        (item :: currentRun) :: doneRuns

                                    else
                                        [ item ] :: currentRun :: doneRuns

                                [] ->
                                    [ item ] :: doneRuns

                        [] ->
                            [ [ item ] ]
                )
                []
                sorted
                |> List.map List.reverse
        )
        groups


{-| The board cell next to which a line's submit button is drawn: the cell just past the end of the
line, or just before its start, preferring whichever is on the board and unoccupied.
-}
submitButtonCell : Bool -> List ( Int, Int ) -> Set ( Int, Int ) -> SeqDict ( Int, Int ) LetterOrWildcard -> ( Int, Int )
submitButtonCell isVertical runCells placedCells board =
    let
        linePos : ( Int, Int ) -> Int
        linePos ( x, y ) =
            if isVertical then
                y

            else
                x

        sorted : List ( Int, Int )
        sorted =
            List.sortBy linePos runCells

        ( dx, dy ) =
            if isVertical then
                ( 0, 1 )

            else
                ( 1, 0 )

        onBoard : ( Int, Int ) -> Bool
        onBoard ( x, y ) =
            x >= 0 && y >= 0 && x < gridSize && y < gridSize

        vacant : ( Int, Int ) -> Bool
        vacant cell =
            not (SeqDict.member cell board) && not (Set.member cell placedCells)

        afterEnd : ( Int, Int )
        afterEnd =
            case List.Extra.last sorted of
                Just ( x, y ) ->
                    ( x + dx, y + dy )

                Nothing ->
                    ( 0, 0 )

        beforeStart : ( Int, Int )
        beforeStart =
            case List.head sorted of
                Just ( x, y ) ->
                    ( x - dx, y - dy )

                Nothing ->
                    ( 0, 0 )
    in
    if onBoard afterEnd && vacant afterEnd then
        afterEnd

    else if onBoard beforeStart && vacant beforeStart then
        beforeStart

    else if onBoard afterEnd then
        afterEnd

    else
        beforeStart


buildPlacedWord : Bool -> Shared -> List ( ( Int, Int ), LetterOrWildcard ) -> Result () PlacedWord
buildPlacedWord isVertical shared placed =
    let
        lineCoord : ( Int, Int ) -> Int
        lineCoord ( x, y ) =
            if isVertical then
                y

            else
                x

        sorted : List ( ( Int, Int ), LetterOrWildcard )
        sorted =
            List.sortBy (\( cell, _ ) -> lineCoord cell) placed

        placedCells : List ( Int, Int )
        placedCells =
            List.map Tuple.first sorted
    in
    case ( List.head placedCells, List.Extra.last placedCells ) of
        ( Just startCell, Just endCell ) ->
            let
                -- Every cell between the first and last placed tile must be filled, either by a
                -- tile placed this turn or a committed tile.
                contiguous : Bool
                contiguous =
                    List.range (lineCoord startCell) (lineCoord endCell)
                        |> List.all
                            (\n ->
                                let
                                    cell : ( Int, Int )
                                    cell =
                                        if isVertical then
                                            ( Tuple.first startCell, n )

                                        else
                                            ( n, Tuple.second startCell )
                                in
                                List.member cell placedCells || SeqDict.member cell shared.board
                            )

                connected : Bool
                connected =
                    placementConnects shared.board placedCells
            in
            case ( contiguous && connected, nonemptyLetters sorted ) of
                ( True, Just letters ) ->
                    Ok { start = startCell, isVertical = isVertical, letters = letters }

                _ ->
                    Err ()

        _ ->
            Err ()


{-| Whether a placement connects to the rest of the board, so words can't float in empty space.
The very first word of the game (when the board is empty) has to cover the centre square; every word
after that has to touch a tile already on the board, either by sitting orthogonally next to one or
by extending through one in its own line (the latter is also adjacency, so this single check covers
it). `placedCells` are the cells the player filled this turn, none of which are on `board` yet.
-}
placementConnects : SeqDict ( Int, Int ) LetterOrWildcard -> List ( Int, Int ) -> Bool
placementConnects board placedCells =
    if SeqDict.isEmpty board then
        List.member centerCell placedCells

    else
        List.any
            (\cell ->
                List.any (\neighbor -> SeqDict.member neighbor board) (orthogonalNeighbors cell)
            )
            placedCells


{-| The centre square, which the first word of the game must cover.
-}
centerCell : ( Int, Int )
centerCell =
    ( gridSize // 2, gridSize // 2 )


{-| The four cells directly above, below, left and right of a cell.
-}
orthogonalNeighbors : ( Int, Int ) -> List ( Int, Int )
orthogonalNeighbors ( x, y ) =
    [ ( x - 1, y ), ( x + 1, y ), ( x, y - 1 ), ( x, y + 1 ) ]


{-| Pull the tiles (letters and wildcards) out of the placed cells in order, failing only if there
are no tiles. Wildcards are kept as `Wildcard`; the letter they stand for is worked out later when
the word is checked against the dictionary (see `bruteForceMatch`).
-}
nonemptyLetters : List ( ( Int, Int ), LetterOrWildcard ) -> Maybe (Nonempty LetterOrWildcard)
nonemptyLetters list =
    List.map Tuple.second list
        |> List.Nonempty.fromList


validateSetup : Id UserId -> Time.Posix -> SetupModel -> Result String ValidatedSetup
validateSetup createdBy time setup =
    case parseTimeControl setup of
        Err error ->
            Err error

        Ok timeControls ->
            case OneOrGreater.fromInt setup.traySize of
                Just traySize ->
                    case parseLettersAndValues setup of
                        Ok letters ->
                            { createdBy = createdBy
                            , timeControls = timeControls
                            , traySize = traySize
                            , fullTrayBonus = setup.fullTrayBonus
                            , seed =
                                -- Round the time to the nearest 10 seconds so that small timing changes don't break an end-to-end test
                                Time.posixToMillis time // 10000 |> (*) 10000 |> (+) (Id.toInt createdBy)
                            , letters = letters
                            , language = setup.language
                            , placeWordAttempts = setup.placeWordAttempts
                            }
                                |> Ok

                        Err error ->
                            Err error

                Nothing ->
                    Err "Tray size must be at least 1"


{-| Turn a running game's setup back into the setup form's fields, so the read-only settings view
(the gear button on an active game) can reuse `setupView` to display them.
-}
validatedToSetupModel : ValidatedSetup -> SetupModel
validatedToSetupModel setup =
    { mainTimeInput = Duration.inMinutes setup.timeControls.mainTime |> String.fromFloat
    , incrementInput = Duration.inSeconds setup.timeControls.increment |> String.fromFloat
    , traySize = OneOrGreater.toInt setup.traySize
    , fullTrayBonus = setup.fullTrayBonus
    , error = Nothing
    , letters =
        NonemptyDict.toList setup.letters
            |> List.map
                (\( letterOrWildcard, data ) ->
                    String.repeat
                        (OneOrGreater.toInt data.count)
                        (letterOrWildcardText letterOrWildcard)
                )
            |> String.concat
    , letterValues =
        NonemptyDict.toList setup.letters
            |> List.filterMap
                (\( letterOrWildcard, data ) ->
                    case letterOrWildcard of
                        Letter (LetterChar char) ->
                            Just ( char, String.fromInt data.value )

                        Wildcard ->
                            Nothing
                )
            |> SeqDict.fromList
    , language = setup.language
    , placeWordAttempts = setup.placeWordAttempts
    , advancedSettingsExpanded = True
    }


wildcardMax : number
wildcardMax =
    2


parseLettersAndValues : SetupModel -> Result String (NonemptyDict LetterOrWildcard { count : OneOrGreater, value : Int })
parseLettersAndValues setup =
    let
        parsedLetters : Result String (NonemptyDict LetterOrWildcard OneOrGreater)
        parsedLetters =
            let
                distributionChars : List Char
                distributionChars =
                    String.toUpper setup.letters
                        |> String.toList
                        |> List.filter (\char -> not (List.member char [ '\n', '\u{000D}', '\t' ]))

                counts : SeqDict LetterOrWildcard OneOrGreater
                counts =
                    List.foldl
                        (\char acc ->
                            if char == ' ' then
                                SeqDictHelper.increment Wildcard acc

                            else
                                SeqDictHelper.increment (Letter (LetterChar char)) acc
                        )
                        SeqDict.empty
                        distributionChars
            in
            case NonemptyDict.fromSeqDict counts of
                Just nonempty ->
                    case NonemptyDict.get Wildcard nonempty of
                        Just value ->
                            if OneOrGreater.toInt value > wildcardMax then
                                Err "No more than 2 wildcards (spaces) are allowed"

                            else
                                Ok nonempty

                        Nothing ->
                            Ok nonempty

                Nothing ->
                    Err "Letters: enter at least one letter"
    in
    case parsedLetters of
        Ok counts ->
            let
                result : Result String (List ( LetterOrWildcard, { count : OneOrGreater, value : Int } ))
                result =
                    List.Nonempty.foldl
                        (\( letterOrWildcard, count ) result2 ->
                            case result2 of
                                Ok list ->
                                    case letterOrWildcard of
                                        Letter (LetterChar char) ->
                                            case String.toInt (String.trim (letterValueInputFor char setup)) of
                                                Just value ->
                                                    Ok (( letterOrWildcard, { count = count, value = value } ) :: list)

                                                Nothing ->
                                                    Err ("Letter values: enter a whole number for " ++ String.fromChar char)

                                        Wildcard ->
                                            Ok (( letterOrWildcard, { count = count, value = 0 } ) :: list)

                                Err error ->
                                    Err error
                        )
                        (Ok [])
                        (NonemptyDict.toNonemptyList counts)
            in
            case result of
                Ok list ->
                    -- The fold prepends, so reverse to keep the distribution's original tile order
                    -- (the bag is built and shuffled in this order, so it affects the drawn trays).
                    case NonemptyDict.fromList (List.reverse list) of
                        Just nonempty ->
                            Ok nonempty

                        Nothing ->
                            Err "Letters: enter at least one letter"

                Err error ->
                    Err error

        Err error ->
            Err error


{-| The current text of a letter's value input, falling back to the letter's default value if the
user hasn't edited it.
-}
letterValueInputFor : Char -> SetupModel -> String
letterValueInputFor char setup =
    case SeqDict.get char setup.letterValues of
        Just input ->
            input

        Nothing ->
            String.fromInt
                (case setup.language of
                    English ->
                        defaultEnglishLetterValue char

                    Swedish ->
                        defaultSwedishLetterValue char
                )


parseTimeControl : SetupModel -> Result String TimeControl
parseTimeControl setup =
    case String.toFloat (String.trim setup.mainTimeInput) of
        Nothing ->
            Err "Main time: enter a number of minutes"

        Just minutes ->
            if minutes <= 0 then
                Err "Main time must be greater than 0"

            else
                case String.toFloat (String.trim setup.incrementInput) of
                    Nothing ->
                        Err "Increment: enter a number of seconds"

                    Just increment ->
                        if increment < 0 then
                            Err "Increment cannot be negative"

                        else
                            Ok { mainTime = Duration.minutes minutes, increment = Duration.seconds increment }


boardX : Coord CssPixels -> Int
boardX windowSize =
    if MyUi.isMobileAlt windowSize then
        0

    else
        MyUi.channelAndGuildColumnWidth windowSize


boardY : number
boardY =
    MyUi.channelHeaderHeight


trayX : Coord CssPixels -> Int
trayX =
    boardX


trayY : OneOrGreater -> Coord CssPixels -> Int
trayY traySize windowSize =
    boardY + boardWidth traySize windowSize


boardWidth : OneOrGreater -> Coord CssPixels -> Int
boardWidth traySize windowSize =
    cellSize traySize windowSize * gridSize


boardHeight : OneOrGreater -> Coord CssPixels -> Int
boardHeight traySize windowSize =
    boardWidth traySize windowSize + trayHeight traySize windowSize


insideBoard : ValidatedSetup -> GameData -> Coord CssPixels -> Coord CssPixels -> Bool
insideBoard setup model windowSize coord =
    if model.showSettings then
        False

    else
        let
            x =
                boardX windowSize
        in
        (Coord.xRaw coord > x)
            && (Coord.xRaw coord < (x + boardWidth setup.traySize windowSize))
            && (Coord.yRaw coord > boardY)
            && (Coord.yRaw coord < boardY + boardHeight setup.traySize windowSize)


{-| Which board cell (if any) a screen position is over.
-}
cellAtPosition : ValidatedSetup -> Coord CssPixels -> Coord CssPixels -> Maybe ( Int, Int )
cellAtPosition setup windowSize coord =
    let
        size : Int
        size =
            cellSize setup.traySize windowSize

        relX : Int
        relX =
            Coord.xRaw coord - boardX windowSize

        relY : Int
        relY =
            Coord.yRaw coord - boardY
    in
    if relX >= 0 && relY >= 0 && (relX // size) < gridSize && (relY // size) < gridSize then
        Just ( relX // size, relY // size )

    else
        Nothing


{-| How much the board is scaled up on mobile once the player has tiles placed on the board this
turn.
-}
boardZoomScale : Float
boardZoomScale =
    1.75


{-| How long, in milliseconds, the board takes to ease to a new zoom/translation.
-}
zoomAnimationDuration : Float
zoomAnimationDuration =
    250


{-| The zoom shown when nothing is placed: fully zoomed out, centred (the focus is irrelevant while
zoomed out, but a stable value keeps the ease-out from panning oddly).
-}
zoomedOutState : ZoomState
zoomedOutState =
    { amount = 0, focusX = 0.5, focusY = 0.5 }


{-| The zoom the board should settle on given the tiles currently placed: fully zoomed in and
centred on their centroid, or fully zoomed out when the board is empty.
-}
zoomTarget : GameData -> ZoomState
zoomTarget model =
    Array.toList model.tiles
        |> List.filterMap
            (\tile ->
                case tile.position of
                    TileOnBoard cell _ ->
                        Just cell

                    TileInTray _ _ ->
                        Nothing
            )
        |> zoomStateForCells


{-| The settled zoom for a board with these tiles placed on it: fully zoomed in and centred on their
centroid, or fully zoomed out when none are placed.
-}
zoomStateForCells : List ( Int, Int ) -> ZoomState
zoomStateForCells placed =
    case placed of
        [] ->
            zoomedOutState

        _ ->
            let
                count : Float
                count =
                    toFloat (List.length placed)

                focusFraction : Int -> Float
                focusFraction total =
                    (toFloat total / count + 0.5) / toFloat gridSize
            in
            { amount = 1
            , focusX = focusFraction (List.sum (List.map Tuple.first placed))
            , focusY = focusFraction (List.sum (List.map Tuple.second placed))
            }


{-| The zoom the board is showing right now: the stored `from` eased towards `zoomTarget` over
`zoomAnimationDuration`.
-}
animatedZoomState : Time.Posix -> GameData -> ZoomState
animatedZoomState time model =
    let
        from : ZoomState
        from =
            model.zoomAnimation.from

        target : ZoomState
        target =
            zoomTarget model

        eased : Float
        eased =
            easeOutCubic (clamp 0 1 (elapsedMs time model.zoomAnimation.start / zoomAnimationDuration))

        lerp : Float -> Float -> Float
        lerp a b =
            a + eased * (b - a)
    in
    { amount = lerp from.amount target.amount
    , focusX = lerp from.focusX target.focusX
    , focusY = lerp from.focusY target.focusY
    }


{-| Start a new zoom animation when a change to the placed tiles moves the zoom target, easing from
whatever the board is showing at `time` towards the new target. When the target is unchanged the
in-flight animation (if any) is left running.
-}
withZoomAnimation : Time.Posix -> GameData -> GameData -> GameData
withZoomAnimation time before after =
    if zoomTarget before == zoomTarget after then
        after

    else
        { after | zoomAnimation = { start = time, from = animatedZoomState time before } }


{-| Whether the mobile board zoom is mid-animation, so the view keeps redrawing each frame.
-}
isZoomAnimating : Time.Posix -> Coord CssPixels -> GameData -> Bool
isZoomAnimating time windowSize model =
    MyUi.isMobileAlt windowSize
        && (zoomTarget model /= model.zoomAnimation.from)
        && (elapsedMs time model.zoomAnimation.start < zoomAnimationDuration)


{-| On mobile the board is zoomed in and centred on the centroid of the placed tiles so the
surrounding cells are larger and easier to tap. The board's on-screen square stays the same size, so
the zoomed-in board is clipped to it. The centre is clamped so the visible window never runs off the
edge of the board (no blank space shows beyond the board), which means the centroid sits dead centre
only when it's far enough from every edge.

Returns the drawn (zoomed) cell size and the board-local translation that positions the zoomed grid
for the board's current (mid-animation) zoom, or `Nothing` when there's effectively no zoom (not on
mobile, or zoomed all the way out). Both `project` in `boardView` and `unprojectTouch` are defined in
terms of these two values, so the drawn board and the touch hit-testing always agree.

-}
boardZoom : Time.Posix -> OneOrGreater -> Coord CssPixels -> GameData -> Maybe { zoomedCellSize : Int, translate : Coord CssPixels }
boardZoom time traySize windowSize model =
    if MyUi.isMobileAlt windowSize then
        resolveZoom traySize windowSize (animatedZoomState time model)

    else
        Nothing


{-| Turn a `ZoomState` into the drawn cell size and board-local translation, or `Nothing` when it's
so close to zoomed out that it's indistinguishable from an unzoomed board (which also lets the grid
background stay cached instead of redrawing).
-}
resolveZoom : OneOrGreater -> Coord CssPixels -> ZoomState -> Maybe { zoomedCellSize : Int, translate : Coord CssPixels }
resolveZoom traySize windowSize zoomState =
    if zoomState.amount < 0.02 then
        Nothing

    else
        let
            size : Int
            size =
                cellSize traySize windowSize

            zc : Int
            zc =
                round ((1 + zoomState.amount * (boardZoomScale - 1)) * toFloat size)

            -- The effective scale is derived from the rounded cell size so that the drawn grid, the
            -- tiles and the touch hit-testing all line up exactly.
            effScale : Float
            effScale =
                toFloat zc / toFloat size

            boardPx : Int
            boardPx =
                gridSize * size

            -- The width/height, in unzoomed board pixels, of the region that stays visible.
            window : Float
            window =
                toFloat boardPx / effScale

            -- The board-local translation for one axis: centre the visible window on the focus, but
            -- clamp it so the window can't run past either edge of the board.
            axisTranslate : Float -> Int
            axisTranslate focusFraction =
                let
                    focusLocal : Float
                    focusLocal =
                        focusFraction * toFloat boardPx

                    left : Float
                    left =
                        clamp 0 (toFloat boardPx - window) (focusLocal - window / 2)
                in
                round (-effScale * left)
        in
        if zc == size then
            -- No visible zoom yet (the amount rounds away); treat it as unzoomed.
            Nothing

        else
            Just
                { zoomedCellSize = zc
                , translate = Coord.xy (axisTranslate zoomState.focusX) (axisTranslate zoomState.focusY)
                }


{-| Map a screen touch position back into the board's unzoomed coordinate space, so the existing
cell math (`cellAtPosition`) resolves it to the right cell even while the board is zoomed in. This is
the exact inverse of the `project` transform in `boardView`. Without zoom it's the identity.
-}
unprojectTouch : Time.Posix -> Coord CssPixels -> ValidatedSetup -> GameData -> Coord CssPixels -> Coord CssPixels
unprojectTouch time windowSize setup model coord =
    case boardZoom time setup.traySize windowSize model of
        Just { zoomedCellSize, translate } ->
            let
                effScale : Float
                effScale =
                    toFloat zoomedCellSize / toFloat (cellSize setup.traySize windowSize)

                unproject : Int -> Int -> Int -> Int
                unproject axis boardOrigin axisTranslate =
                    boardOrigin + round ((toFloat (axis - boardOrigin) - toFloat axisTranslate) / effScale)
            in
            Coord.xy
                (unproject (Coord.xRaw coord) (boardX windowSize) (Coord.xRaw translate))
                (unproject (Coord.yRaw coord) boardY (Coord.yRaw translate))

        Nothing ->
            coord


{-| Which board cell (if any) a screen touch is over, taking the mobile zoom into account. Only a
touch actually within the board's on-screen square counts; a touch over the tray (or anywhere else
outside the board) is `Nothing`. Without this guard the zoom un-projection could pull a touch just
below the board (e.g. dropping a tile back on the tray) up into the board's cell range.
-}
boardCellAtPosition : Time.Posix -> Coord CssPixels -> ValidatedSetup -> GameData -> Coord CssPixels -> Maybe ( Int, Int )
boardCellAtPosition time windowSize setup model coord =
    let
        relX : Int
        relX =
            Coord.xRaw coord - boardX windowSize

        relY : Int
        relY =
            Coord.yRaw coord - boardY

        width : Int
        width =
            boardWidth setup.traySize windowSize
    in
    if relX >= 0 && relX < width && relY >= 0 && relY < width then
        cellAtPosition setup windowSize (unprojectTouch time windowSize setup model coord)

    else
        Nothing


trayTileSize : OneOrGreater -> Coord CssPixels -> Float
trayTileSize traySize windowSize =
    let
        -- One slot per tray tile plus one more for the replace-tray button drawn next to the tray.
        slots : Float
        slots =
            toFloat (OneOrGreater.toInt traySize + 1)
    in
    min 50 ((toFloat (Coord.xRaw windowSize) - (trayTileSpacing * (slots - 1))) / slots)


trayTileSpacing : number
trayTileSpacing =
    4


trayTilePos : OneOrGreater -> Coord CssPixels -> TrayIndex -> Coord CssPixels
trayTilePos traySize windowSize (TrayIndex index) =
    Coord.xy
        (boardX windowSize + round (toFloat index * (trayTileSize traySize windowSize + trayTileSpacing)))
        (trayY traySize windowSize)


{-| The screen coordinate at the centre of a tray slot, used by end-to-end tests to touch a tile.
-}
trayTouchCoord : OneOrGreater -> Coord CssPixels -> Int -> Coord CssPixels
trayTouchCoord traySize windowSize slot =
    let
        pos : Coord CssPixels
        pos =
            trayTilePos traySize windowSize (TrayIndex slot)

        half : Int
        half =
            round (trayTileSize traySize windowSize) // 2
    in
    Coord.xy (Coord.xRaw pos + half) (Coord.yRaw pos + half)


{-| The screen coordinate to touch to drop a tile on board cell `( tx, ty )`, given the tiles the
current player has already placed this turn (which is what the mobile zoom centres on). Used by
end-to-end tests, this is the forward of the `unprojectTouch` hit-test: touching here resolves back
to `( tx, ty )`. The zoom is taken as settled (as it is a frame after the previous drop).
-}
boardTouchCoord : OneOrGreater -> Coord CssPixels -> List ( Int, Int ) -> ( Int, Int ) -> Coord CssPixels
boardTouchCoord traySize windowSize placedCells ( tx, ty ) =
    let
        size : Int
        size =
            cellSize traySize windowSize
    in
    case resolveZoom traySize windowSize (zoomStateForCells placedCells) of
        Just { zoomedCellSize, translate } ->
            let
                effScale : Float
                effScale =
                    toFloat zoomedCellSize / toFloat size

                project2 : Int -> Int -> Int -> Int
                project2 cell boardOrigin axisTranslate =
                    boardOrigin + axisTranslate + round (effScale * (toFloat (cell * size) + toFloat size / 2))
            in
            Coord.xy
                (project2 tx (boardX windowSize) (Coord.xRaw translate))
                (project2 ty boardY (Coord.yRaw translate))

        Nothing ->
            Coord.xy
                (boardX windowSize + tx * size + size // 2)
                (boardY + ty * size + size // 2)


{-| Where a tray tile is currently drawn. While a shift animation is in progress the tile eases
from the slot it was shifted out of toward its current slot; otherwise it sits at its current slot.
-}
animatedTrayTilePos : ValidatedSetup -> Coord CssPixels -> Time.Posix -> TrayIndex -> Maybe ( Time.Posix, Int ) -> Coord CssPixels
animatedTrayTilePos setup windowSize currentTime trayIndex shiftAnimation =
    let
        dest : Coord CssPixels
        dest =
            trayTilePos setup.traySize windowSize trayIndex
    in
    case shiftAnimation of
        Just ( startTime, fromSlot ) ->
            let
                eased : Float
                eased =
                    clamp 0 1 (elapsedMs currentTime startTime / trayShiftDuration)

                from : Coord CssPixels
                from =
                    trayTilePos setup.traySize windowSize (TrayIndex fromSlot)

                lerp : Int -> Int -> Int
                lerp a b =
                    round (toFloat a + eased * toFloat (b - a))
            in
            Coord.xy
                (lerp (Coord.xRaw from) (Coord.xRaw dest))
                (lerp (Coord.yRaw from) (Coord.yRaw dest))

        Nothing ->
            dest


{-| Which tray slot (if any) a screen position is over.
-}
trayIndexAtPosition : ValidatedSetup -> Coord CssPixels -> Coord CssPixels -> Int -> Maybe Int
trayIndexAtPosition setup windowSize coord trayLength =
    let
        relX : Int
        relX =
            Coord.xRaw coord - trayX windowSize

        relY : Int
        relY =
            Coord.yRaw coord - trayY setup.traySize windowSize

        index =
            toFloat relX / (trayTileSize setup.traySize windowSize + trayTileSpacing) |> floor
    in
    if relX >= 0 && relY >= 0 && relY < trayHeight setup.traySize windowSize && index < trayLength then
        Just index

    else
        Nothing


getPlayer : Id UserId -> Shared -> Maybe Player
getPlayer userId shared =
    List.Extra.find (\player -> player.userId == userId) (List.Nonempty.toList shared.players)


dragStart : Time.Posix -> Coord CssPixels -> Id UserId -> NonemptyDict Int Touch -> ValidatedSetup -> Shared -> GameData -> GameData
dragStart time windowSize currentUserId touches setup shared gameModel =
    if gameModel.showSettings then
        -- The settings view covers the board, so a drag over where the board would be shouldn't
        -- move any tiles.
        gameModel

    else
        dragStartHelper time windowSize currentUserId touches setup shared gameModel


dragStartHelper : Time.Posix -> Coord CssPixels -> Id UserId -> NonemptyDict Int Touch -> ValidatedSetup -> Shared -> GameData -> GameData
dragStartHelper time windowSize currentUserId touches setup shared oldModel =
    let
        -- Tiles that another player's move covered belong back in the tray; find the touched
        -- tile in (and store) that corrected state so the drag matches what the view is showing.
        gameModel : GameData
        gameModel =
            { oldModel | tiles = getTiles windowSize currentUserId setup shared oldModel.tiles }

        touchPosition : Coord CssPixels
        touchPosition =
            Touch.touchCentroid touches

        trayList =
            Array.toList gameModel.tiles
    in
    case boardCellAtPosition time windowSize setup gameModel touchPosition of
        Just cell ->
            case
                List.Extra.findIndex
                    (\tile ->
                        case tile.position of
                            TileOnBoard boardPosition _ ->
                                boardPosition == cell

                            TileInTray _ _ ->
                                False
                    )
                    trayList
            of
                Just tileIndex ->
                    { gameModel | dragging = Dragging tileIndex }

                Nothing ->
                    gameModel

        Nothing ->
            case trayIndexAtPosition setup windowSize touchPosition (OneOrGreater.toInt setup.traySize) of
                Just index ->
                    case
                        List.Extra.findIndex
                            (\tile ->
                                case tile.position of
                                    TileOnBoard _ _ ->
                                        False

                                    TileInTray trayIndex _ ->
                                        trayIndex == TrayIndex index
                            )
                            trayList
                    of
                        Just tileIndex ->
                            -- Grabbing a tray tile also dismisses the word-definition popup, so the
                            -- overlay version doesn't sit on top of the board while the player plays.
                            { gameModel
                                | dragging = Dragging tileIndex
                                , highlightedPlayer = Nothing
                                , wordDefinition = WordDefinition_None
                            }

                        Nothing ->
                            gameModel

                Nothing ->
                    gameModel


dragEnd :
    Time.Posix
    -> Coord CssPixels
    -> Id UserId
    -> NonemptyDict Int Touch
    -> ValidatedSetup
    -> Shared
    -> GameData
    -> ( GameData, Bool )
dragEnd currentTime windowSize currentUserId newTouches setup shared oldModel =
    let
        -- Tiles that another player's move covered belong back in the tray; drop the dragged
        -- tile into (and store) that corrected state so it can't land on a stale layout.
        model : GameData
        model =
            { oldModel | tiles = getTiles windowSize currentUserId setup shared oldModel.tiles }
    in
    case model.dragging of
        Dragging tileIndex ->
            let
                shouldEndPremove : Maybe ( Int, Int ) -> Bool
                shouldEndPremove newPosition =
                    case ( getPlayer currentUserId shared, Array.get tileIndex model.tiles ) of
                        ( Just player, Just tile ) ->
                            case ( player.premove, tile.position ) of
                                ( Just ( _, result, _ ), TileOnBoard ( x, y ) _ ) ->
                                    if List.any (\( ( xA, yA ), _ ) -> xA == x && yA == y) result.placedCells then
                                        newPosition /= Just ( x, y )

                                    else
                                        False

                                _ ->
                                    False

                        _ ->
                            False

                position : Coord CssPixels
                position =
                    Touch.touchCentroid newTouches

                returnToTray : ( GameData, Bool )
                returnToTray =
                    ( (if distanceToTray setup windowSize position (Array.length model.tiles) <= maxTraySnapDistance then
                        { model
                            | dragging = NotDragging
                            , tiles = insertIntoTray currentTime windowSize tileIndex position setup model.tiles
                        }

                       else
                        { model
                            | dragging = NotDragging
                            , tiles =
                                Array.Extra.update
                                    tileIndex
                                    (\tile -> { tile | position = TileInTray (firstOpenTrayIndex (Just tileIndex) model.tiles) Nothing })
                                    model.tiles
                        }
                      )
                        |> withZoomAnimation currentTime model
                    , shouldEndPremove Nothing
                    )
            in
            case boardCellAtPosition currentTime windowSize setup model position of
                Just cell ->
                    if SeqDict.member cell shared.board || cellOccupiedByOtherTile tileIndex cell model.tiles then
                        returnToTray

                    else
                        ( { model
                            | dragging = NotDragging
                            , tiles =
                                Array.Extra.update
                                    tileIndex
                                    (\tile -> { tile | position = TileOnBoard cell currentTime })
                                    model.tiles
                          }
                            |> withZoomAnimation currentTime model
                        , shouldEndPremove (Just cell)
                        )

                Nothing ->
                    returnToTray

        NotDragging ->
            ( model, False )


{-| The tray slots currently occupied by tiles resting in the tray (board tiles don't count).
-}
trayIndicesInUse : Array Tile -> Set Int
trayIndicesInUse tiles =
    Array.foldl
        (\tile set ->
            case tile.position of
                TileInTray (TrayIndex index) _ ->
                    Set.insert index set

                TileOnBoard _ _ ->
                    set
        )
        Set.empty
        tiles


{-| The lowest tray index at or above `n` that isn't in `taken`.
-}
lowestFreeTrayIndex : Int -> Set Int -> Int
lowestFreeTrayIndex n taken =
    if Set.member n taken then
        lowestFreeTrayIndex (n + 1) taken

    else
        n


{-| The lowest tray slot not occupied by another tile, used when a dragged tile is returned to
the tray.
-}
firstOpenTrayIndex : Maybe Int -> Array Tile -> TrayIndex
firstOpenTrayIndex draggedIndex tiles =
    let
        occupied : List Int
        occupied =
            Array.toIndexedList tiles
                |> List.filterMap
                    (\( index, tile ) ->
                        if Just index == draggedIndex then
                            Nothing

                        else
                            case tile.position of
                                TileInTray (TrayIndex trayIndex) _ ->
                                    Just trayIndex

                                TileOnBoard _ _ ->
                                    Nothing
                    )

        find : Int -> Int
        find n =
            if List.member n occupied then
                find (n + 1)

            else
                n
    in
    TrayIndex (find 0)


cellOccupiedByOtherTile : Int -> ( Int, Int ) -> Array Tile -> Bool
cellOccupiedByOtherTile draggedIndex cell tiles =
    Array.toIndexedList tiles
        |> List.any
            (\( index, tile ) ->
                case tile.position of
                    TileOnBoard pos _ ->
                        (index /= draggedIndex) && pos == cell

                    TileInTray _ _ ->
                        False
            )


{-| How close (in CSS pixels) the cursor has to be to the tray for a dropped tile to snap into it
rather than fall back to the first open slot.
-}
maxTraySnapDistance : number
maxTraySnapDistance =
    100


{-| The distance (in CSS pixels) from a screen position to the nearest edge of the tray rectangle,
or 0 when the position is inside it.
-}
distanceToTray : ValidatedSetup -> Coord CssPixels -> Coord CssPixels -> Int -> Float
distanceToTray setup windowSize coord slotCount =
    let
        left : Int
        left =
            trayX windowSize

        right : Int
        right =
            left + round (toFloat slotCount * trayTileSize setup.traySize windowSize) + (slotCount - 1) * trayTileSpacing

        top : Int
        top =
            trayY setup.traySize windowSize

        bottom : Int
        bottom =
            top + trayHeight setup.traySize windowSize

        dx : Int
        dx =
            max 0 (max (left - Coord.xRaw coord) (Coord.xRaw coord - right))

        dy : Int
        dy =
            max 0 (max (top - Coord.yRaw coord) (Coord.yRaw coord - bottom))
    in
    sqrt (toFloat (dx * dx + dy * dy))


{-| The tray slot a dropped tile lands in, given the tray tile size, the tray's left edge, the
dropped tile's centre x (the tile is drawn centred on the cursor while dragging) and the number of
slots.

We snap to the slot whose centre is nearest the cursor. Subtracting half a tile is what lines the
cursor up with slot _centres_ rather than slot _left edges_: without it a tile dropped anywhere right
of a slot's centre snaps a whole slot too far to the right.

-}
trayDropSlot : Float -> Int -> Int -> Int -> Int
trayDropSlot tileSize trayLeft centerX slotCount =
    (toFloat (centerX - trayLeft) - tileSize / 2)
        / (tileSize + trayTileSpacing)
        |> round
        |> clamp 0 (slotCount - 1)


{-| Drop the dragged tile into the tray slot nearest the cursor, shifting the tiles between that
slot and the nearest empty slot over by one to make room.
-}
insertIntoTray : Time.Posix -> Coord CssPixels -> Int -> Coord CssPixels -> ValidatedSetup -> Array Tile -> Array Tile
insertIntoTray currentTime windowSize tileIndex position setup tiles =
    let
        slotCount : Int
        slotCount =
            Array.length tiles

        target : Int
        target =
            trayDropSlot (trayTileSize setup.traySize windowSize) (trayX windowSize) (Coord.xRaw position) slotCount

        occupied : Set Int
        occupied =
            Array.toIndexedList tiles
                |> List.filterMap
                    (\( index, tile ) ->
                        if index == tileIndex then
                            Nothing

                        else
                            case tile.position of
                                TileInTray (TrayIndex slot) _ ->
                                    Just slot

                                TileOnBoard _ _ ->
                                    Nothing
                    )
                |> Set.fromList

        rightFree : Maybe Int
        rightFree =
            List.range (target + 1) (slotCount - 1)
                |> List.filter (\slot -> not (Set.member slot occupied))
                |> List.head

        leftFree : Maybe Int
        leftFree =
            List.range 0 (target - 1)
                |> List.filter (\slot -> not (Set.member slot occupied))
                |> List.maximum

        shiftRight : Int -> Int -> Int
        shiftRight free slot =
            if slot >= target && slot < free then
                slot + 1

            else
                slot

        shiftLeft : Int -> Int -> Int
        shiftLeft free slot =
            if slot > free && slot <= target then
                slot - 1

            else
                slot

        slotMapping : Int -> Int
        slotMapping =
            if not (Set.member target occupied) then
                identity

            else
                case ( leftFree, rightFree ) of
                    ( Just l, Just r ) ->
                        if target - l <= r - target then
                            shiftLeft l

                        else
                            shiftRight r

                    ( Just l, Nothing ) ->
                        shiftLeft l

                    ( Nothing, Just r ) ->
                        shiftRight r

                    ( Nothing, Nothing ) ->
                        identity
    in
    Array.indexedMap
        (\index tile ->
            if index == tileIndex then
                -- The dropped tile appears straight at its slot (it was following the
                -- cursor, so there's no old tray slot to slide from).
                { tile | position = TileInTray (TrayIndex target) Nothing }

            else
                case tile.position of
                    TileInTray (TrayIndex slot) _ ->
                        let
                            newSlot : Int
                            newSlot =
                                slotMapping slot
                        in
                        if newSlot == slot then
                            tile

                        else
                            { tile | position = TileInTray (TrayIndex newSlot) (Just ( currentTime, slot )) }

                    TileOnBoard _ _ ->
                        tile
        )
        tiles


type UserStatus
    = NotJoined
    | Joined
    | JoinedAndItsTheirTurn


isPlayerTurn : Id UserId -> Shared -> UserStatus
isPlayerTurn userId shared =
    case List.Extra.findIndex (\player -> player.userId == userId) (List.Nonempty.toList shared.players) of
        Just index ->
            if index == modBy (List.Nonempty.length shared.players) shared.turnCount then
                JoinedAndItsTheirTurn

            else
                Joined

        Nothing ->
            NotJoined


tileSlideDuration : Duration
tileSlideDuration =
    Duration.milliseconds 250


tileSlideStagger : Duration
tileSlideStagger =
    Duration.milliseconds 80


{-| How long, in milliseconds, rejected tiles sit on the board (turned red) before sliding back
off again.
-}
invalidHoldDuration : Duration
invalidHoldDuration =
    Duration.milliseconds 2000


tileFadeDelay : Duration
tileFadeDelay =
    Duration.milliseconds 1000


{-| How long, in milliseconds, the fade-and-drift into place itself takes, once it starts.
-}
tileFadeDuration : Float
tileFadeDuration =
    100


{-| How far, as a fraction of a tile's size, a new tile starts above its final spot before it
descends into place.
-}
tileFadeDrift : Float
tileFadeDrift =
    0.2


{-| How long, in milliseconds, a tray tile takes to slide from its old slot to its new one when
another tile is inserted next to it.
-}
trayShiftDuration : Float
trayShiftDuration =
    200


{-| Whether a tile is still within its fade-in window, so the view keeps redrawing each animation
frame until it has settled.
-}
isTileFading : Time.Posix -> Time.Posix -> Bool
isTileFading currentTime createdAt =
    elapsedMs currentTime createdAt < Duration.inMilliseconds tileFadeDelay + tileFadeDuration


{-| Whether a tray tile is partway through sliding from an old slot to a new one.
-}
isTileShifting : Time.Posix -> Tile -> Bool
isTileShifting currentTime tile =
    case tile.position of
        TileInTray _ (Just ( startTime, _ )) ->
            elapsedMs currentTime startTime < trayShiftDuration

        _ ->
            False


elapsedMs : Time.Posix -> Time.Posix -> Float
elapsedMs currentTime startTime =
    toFloat (Time.posixToMillis currentTime - Time.posixToMillis startTime)


{-| The moment, in milliseconds since the placement started, at which the last tile has finished
sliding in.
-}
slideInEnd : Int -> Duration
slideInEnd tileCount =
    Quantity.multiplyBy (toFloat (max 0 (tileCount - 1))) (Quantity.plus tileSlideStagger tileSlideDuration)


{-| The total length of a placement's animation. A valid placement just slides in; a rejected one
also holds and then slides back off.
-}
placementAnimationDuration : ToBeFilledInByBackend IsValid -> Int -> Duration
placementAnimationDuration isValid tileCount =
    case isValid of
        FilledInByBackend IsNotValid ->
            Quantity.sum [ slideInEnd tileCount, invalidHoldDuration, slideInEnd tileCount ]

        _ ->
            slideInEnd tileCount


{-| Whether a placement animation is currently in progress, so the view should keep redrawing
each animation frame.
-}
isAnimating : Time.Posix -> Shared -> Bool
isAnimating currentTime shared =
    case shared.lastPlacement of
        Just placement ->
            elapsedMs currentTime placement.startTime
                < Duration.inMilliseconds (placementAnimationDuration placement.isValid (List.length placement.cells))

        Nothing ->
            False


{-| Whether any tile is still fading in, so the view should keep redrawing each animation frame.
-}
anyTileAnimating : Time.Posix -> GameData -> Bool
anyTileAnimating currentTime model =
    Array.Extra.any (\tile -> isTileFading currentTime tile.createdAt || isTileShifting currentTime tile) model.tiles


{-| The opacity and downward drift of a tile as it fades into place. It stays hidden for
`tileFadeDelay` after being created, then quickly fades and drifts down over `tileFadeDuration`.
`opacity` runs 0 to 1; `drift` is the fraction of a tile's size the tile still sits above its final
spot (1 before/at the start of the fade, easing to 0 once settled).
-}
tileFade : Time.Posix -> Time.Posix -> { opacity : Float, drift : Float }
tileFade currentTime createdAt =
    let
        progress : Float
        progress =
            clamp 0 1 ((elapsedMs currentTime createdAt - Duration.inMilliseconds tileFadeDelay) / tileFadeDuration)
    in
    { opacity = progress, drift = 1 - easeOutCubic progress }


easeOutCubic : Float -> Float
easeOutCubic t =
    let
        clamped : Float
        clamped =
            clamp 0 1 t
    in
    1 - (1 - clamped) ^ 3


{-| Where one placed tile is in its animation, given the time elapsed since the placement, the
total number of tiles (for the staggering) and the tile's index. `progress` is 0 when the tile is
at the board's top-left corner and 1 when it's resting on its destination cell; `red` is set once
a rejected tile has landed and is on its way back off. `Nothing` means the tile shouldn't be drawn
(a rejected tile that has finished leaving).
-}
animatedTilePlacement : Bool -> Float -> ToBeFilledInByBackend IsValid -> Int -> Int -> Maybe { progress : Float, red : Bool }
animatedTilePlacement isPlayerWhoPlacedTiles elapsed isValid tileCount index =
    let
        launch : Float
        launch =
            toFloat index * Duration.inMilliseconds tileSlideStagger

        slideEnd : Float
        slideEnd =
            launch + Duration.inMilliseconds tileSlideDuration

        slideInProgress : Float
        slideInProgress =
            if isPlayerWhoPlacedTiles then
                1

            else if elapsed < launch then
                0

            else
                easeOutCubic ((elapsed - launch) / Duration.inMilliseconds tileSlideDuration)
    in
    case isValid of
        FilledInByBackend IsNotValid ->
            let
                leaveStart : Float
                leaveStart =
                    Quantity.sum
                        [ invalidHoldDuration
                        , Quantity.multiplyBy (toFloat index) tileSlideStagger
                        , slideInEnd tileCount
                        ]
                        |> Duration.inMilliseconds

                leaveEnd : Float
                leaveEnd =
                    leaveStart + Duration.inMilliseconds tileSlideDuration
            in
            if elapsed < slideEnd then
                Just { progress = slideInProgress, red = False }

            else if elapsed < (leaveStart + slideEnd) * 0.5 then
                Just { progress = 1, red = False }

            else if elapsed < leaveStart then
                Just { progress = 1, red = True }

            else if elapsed < leaveEnd then
                Just
                    { progress = 1 - easeOutCubic ((elapsed - leaveStart) / Duration.inMilliseconds tileSlideDuration)
                    , red = True
                    }

            else
                Nothing

        _ ->
            Just { progress = slideInProgress, red = False }


{-| The board cells currently being drawn by the placement animation, which are therefore left out
of the ordinary committed-tile rendering to avoid drawing them twice.
-}
animatingCells : Time.Posix -> Shared -> Set ( Int, Int )
animatingCells currentTime shared =
    case shared.lastPlacement of
        Just placement ->
            if isAnimating currentTime shared then
                List.map Tuple.first placement.cells |> Set.fromList

            else
                Set.empty

        Nothing ->
            Set.empty


type PassBehavior
    = ShouldReplaceTray
    | ShouldPass
    | ShouldEndGame


passBehavior : ValidatedSetup -> Shared -> PassBehavior
passBehavior setup shared =
    if remainingLettersInBag setup shared.board (List.Nonempty.toList shared.players) == SeqDict.empty then
        case shared.passingStartedAt of
            Just passingStartedAt ->
                if List.Nonempty.length shared.players > shared.turnCount + 1 - passingStartedAt then
                    ShouldPass

                else
                    ShouldEndGame

            Nothing ->
                ShouldPass

    else
        ShouldReplaceTray


gameView :
    Time.Posix
    -> Coord CssPixels
    -> Maybe (NonemptyDict Int Touch)
    -> Bool
    -> LocalUser
    -> ValidatedSetup
    -> Array ActionWithTime
    -> Shared
    -> GameData
    -> Element GameMsg
gameView currentTime windowSize maybeDragging isPersonalDm localUser setup actions shared oldModel =
    let
        -- Tiles that another player's move covered belong back in the tray; render that
        -- corrected state instead of the raw stored tiles.
        model : GameData
        model =
            { oldModel | tiles = getTiles windowSize localUser.session.userId setup shared oldModel.tiles }

        isMobile =
            MyUi.isMobileAlt windowSize

        -- The board cells placed by the player whose name was clicked in the status view, drawn with
        -- a highlight so their letters stand out. Empty when no player is selected.
        highlightedCells : Set ( Int, Int )
        highlightedCells =
            case model.highlightedPlayer of
                Just userId ->
                    SeqDict.foldl
                        (\cell owner acc ->
                            if owner == userId then
                                Set.insert cell acc

                            else
                                acc
                        )
                        Set.empty
                        (tileOwners setup actions)

                Nothing ->
                    Set.empty

        -- A gear in the top right corner that toggles between the game and its (read-only)
        -- settings, so players can check what was configured for the match.
        settingsButton : Ui.Attribute GameMsg
        settingsButton =
            (if isMobile then
                MyUi.elButton
                    (Dom.id "wsg_settings")
                    PressedToggleSettings
                    [ Ui.width (Ui.px 40)
                    , Ui.padding 8
                    , Ui.alignRight
                    , Ui.alignBottom
                    , Ui.Font.color MyUi.font1
                    , Ui.Accessibility.description "Game settings"
                    , Ui.background MyUi.background1
                    ]
                    (Ui.html Icons.gear)

             else
                MyUi.elButton
                    (Dom.id "wsg_settings")
                    PressedToggleSettings
                    [ Ui.width (Ui.px 40)
                    , Ui.padding 8
                    , Ui.alignRight
                    , case ( wideEnoughForDefinitionColumn windowSize, model.wordDefinition ) of
                        ( True, WordDefinition_Open _ _ ) ->
                            Ui.move { x = -wordDefinitionColumnWidth, y = 0, z = 0 }

                        _ ->
                            Ui.noAttr
                    , Ui.Font.color MyUi.font1
                    , Ui.Accessibility.description "Game settings"
                    ]
                    (Ui.html Icons.gear)
            )
                |> Ui.inFront
    in
    if model.showSettings then
        Ui.el
            [ settingsButton ]
            (setupView windowSize True (validatedToSetupModel setup) |> Ui.map (\_ -> PressedToggleSettings))

    else
        let
            boardPx : Int
            boardPx =
                cellSize setup.traySize windowSize * gridSize

            wideEnough : Bool
            wideEnough =
                wideEnoughForDefinitionColumn windowSize

            overlayAttr : Ui.Attribute GameMsg
            overlayAttr =
                case ( wideEnough, model.wordDefinition ) of
                    ( False, WordDefinition_Open open data ) ->
                        Ui.inFront (wordDefinitionOverlay boardPx open data)

                    _ ->
                        Ui.noAttr
        in
        (if isMobile then
            Ui.column

         else
            Ui.row
        )
            [ Ui.height (Ui.px (tabBodyHeight windowSize setup.traySize))
            , Ui.background MyUi.tabBackground
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border2
            , MyUi.noShrinking
            , settingsButton
            , Ui.contentTop
            , overlayAttr
            ]
            ([ boardView currentTime windowSize maybeDragging localUser setup shared highlightedCells model
             , statusView windowSize isPersonalDm localUser setup actions shared model
             ]
                ++ (case ( wideEnough, model.wordDefinition ) of
                        ( True, WordDefinition_Open open data ) ->
                            [ wordDefinitionColumn windowSize setup open data ]

                        _ ->
                            []
                   )
            )


playerRowHeight : number
playerRowHeight =
    User.profileImageSize


lettersLeftHeight : number
lettersLeftHeight =
    40


playerRowSpacing : number
playerRowSpacing =
    8


playerRow : LocalUser -> Id UserId -> Bool -> Bool -> String -> Element GameMsg
playerRow localUser userId highlight isSelected suffix =
    let
        maybeUser : Maybe User.FrontendUser
        maybeUser =
            User.getUser userId localUser
    in
    MyUi.rowButton
        (Dom.id ("wsg_player_" ++ Id.toString userId))
        (PressedPlayerRow userId)
        [ Ui.spacing 8
        , Ui.width Ui.shrink
        , Ui.Events.onMouseEnter (MouseEnterPlayerRow userId)
        , Ui.Events.onMouseLeave (MouseExitPlayerRow userId)
        , if highlight then
            Ui.background MyUi.mentionColor

          else
            Ui.noAttr
        , MyUi.htmlStyle
            "outline"
            (if isSelected then
                "4px solid rgb(40, 90, 220)"

             else
                "0 solid rgba(0,0,0,0)"
            )
        , Ui.rounded 8
        , Ui.paddingWith { left = 0, top = 0, bottom = 0, right = 8 }
        , Ui.clip
        ]
        [ if highlight then
            User.profileImageNoRounding userId (Maybe.andThen .icon maybeUser)

          else
            User.profileImage userId (Maybe.andThen .icon maybeUser)
        , Ui.row
            [ MyUi.prewrap ]
            [ Ui.el
                [ Ui.Font.bold ]
                (Ui.text
                    (case maybeUser of
                        Just user ->
                            PersonName.toString user.name

                        Nothing ->
                            "<missing>"
                    )
                )
            , Ui.text suffix
            ]
        ]


{-| The mobile status view's compact "X's turn" / "X is next" row. Like `playerRow`, clicking it
highlights that player's placed letters on the board; `highlight` shades the row whose turn it is.
-}
mobilePlayerRow : Maybe (Id UserId) -> Id UserId -> Bool -> User.FrontendUser -> String -> Element GameMsg
mobilePlayerRow highlightedPlayer userId highlight user suffix =
    MyUi.rowButton
        -- `highlight` distinguishes the current-turn row from the "is next" row; they can name the
        -- same player in a solo game, so it keeps the two button ids from colliding.
        (Dom.id
            ("wsg_playerMobile_"
                ++ (if highlight then
                        "current_"

                    else
                        "next_"
                   )
                ++ Id.toString userId
            )
        )
        (PressedPlayerRow userId)
        [ Ui.width Ui.shrink
        , Ui.paddingXY 8 2
        , if highlight then
            Ui.background MyUi.mentionColor

          else
            Ui.noAttr

        -- A transparent border is always present so selecting a row doesn't shift the layout.
        , Ui.border 2
        , Ui.borderColor
            (if highlightedPlayer == Just userId then
                Ui.rgb 40 90 220

             else
                Ui.rgba 0 0 0 0
            )
        , Ui.rounded 4
        , MyUi.htmlStyle "cursor" "pointer"
        ]
        [ Ui.el [ Ui.Font.bold ] (Ui.text (PersonName.toString user.name))
        , Ui.text suffix
        ]


leaderboardView : Bool -> Maybe (Id UserId) -> Nonempty (Id UserId) -> Shared -> LocalUser -> List (Element GameMsg)
leaderboardView isMobile highlightedPlayer winners shared localUser =
    let
        isTie : Bool
        isTie =
            List.Nonempty.length winners > 1

        sortedPlayers : List Player
        sortedPlayers =
            List.Nonempty.toList shared.players
                |> List.sortBy (\player -> negate player.score)
    in
    List.filterMap
        (\player ->
            let
                isWinner : Bool
                isWinner =
                    List.Nonempty.member player.userId winners
            in
            if isMobile && not isWinner then
                Nothing

            else
                playerRow
                    localUser
                    player.userId
                    isWinner
                    (highlightedPlayer == Just player.userId)
                    (": "
                        ++ String.fromInt player.score
                        ++ (if isWinner then
                                if isTie then
                                    " (tied for first)"

                                else
                                    " (winner)"

                            else
                                ""
                           )
                    )
                    |> Just
        )
        sortedPlayers


joinWarning : Bool -> Int -> LocalUser -> Shared -> Maybe (Element GameMsg)
joinWarning isPersonalDm playerCount localUser shared =
    let
        soloJoinWarning : Bool
        soloJoinWarning =
            not isPersonalDm
                && (playerCount == 1)
                && (shared.turnCount == 1)
                && (isPlayerTurn localUser.session.userId shared == JoinedAndItsTheirTurn)
    in
    if soloJoinWarning then
        Ui.el
            [ Ui.Font.color MyUi.errorColor, MyUi.prewrap, Ui.paddingXY 16 0 ]
            (Ui.text "No one else has joined yet.\nOnce you make a second move no one can join.")
            |> Just

    else
        Nothing


statusView : Coord CssPixels -> Bool -> LocalUser -> ValidatedSetup -> Array ActionWithTime -> Shared -> GameData -> Element GameMsg
statusView windowSize isPersonalDm localUser setup actions shared model =
    let
        currentPlayer : Player
        currentPlayer =
            List.Nonempty.get shared.turnCount shared.players

        nextPlayer : Player
        nextPlayer =
            List.Nonempty.get (shared.turnCount + 1) shared.players

        playerCount =
            List.Nonempty.length shared.players

        isMobile =
            MyUi.isMobileAlt windowSize

        winners =
            getWinner shared
    in
    if isMobile then
        Ui.row
            [ Ui.paddingXY 8 0, Ui.spacing 8, Ui.height (Ui.px statusHeight), MyUi.prewrap ]
            [ Ui.column
                [ Ui.centerY ]
                (case winners of
                    Just ( winners2, _ ) ->
                        leaderboardView isMobile model.highlightedPlayer winners2 shared localUser

                    Nothing ->
                        [ case User.getUser currentPlayer.userId localUser of
                            Just user ->
                                mobilePlayerRow
                                    model.highlightedPlayer
                                    currentPlayer.userId
                                    True
                                    user
                                    ("'s turn (" ++ String.fromInt currentPlayer.score ++ ")")

                            Nothing ->
                                Ui.none
                        , case User.getUser nextPlayer.userId localUser of
                            Just user ->
                                mobilePlayerRow
                                    model.highlightedPlayer
                                    nextPlayer.userId
                                    False
                                    user
                                    (" is next (" ++ String.fromInt nextPlayer.score ++ ")")

                            Nothing ->
                                Ui.none
                        , joinWarning isPersonalDm playerCount localUser shared |> Maybe.withDefault Ui.none
                        ]
                )
            ]

    else
        Ui.column
            [ case joinWarning isPersonalDm playerCount localUser shared of
                Just element ->
                    Ui.inFront (Ui.el [ Ui.alignBottom, Ui.paddingXY 0 8 ] element)

                Nothing ->
                    Ui.noAttr
            ]
            [ case winners of
                Just _ ->
                    Ui.el
                        [ Ui.paddingXY 16 0
                        , Ui.Font.bold
                        , Ui.contentCenterY
                        , Ui.height (Ui.px lettersLeftHeight)
                        ]
                        (Ui.text "Game over")

                Nothing ->
                    Ui.row
                        [ Ui.paddingXY 16 0
                        , Ui.contentCenterY
                        , Ui.height (Ui.px lettersLeftHeight)
                        , Ui.Font.color MyUi.font3
                        , MyUi.prewrap
                        ]
                        (case remainingLettersInBagCount setup shared.board (List.Nonempty.toList shared.players) of
                            1 ->
                                [ Ui.el [ Ui.Font.bold, Ui.width Ui.shrink ] (Ui.text "1"), Ui.text " letter left!" ]

                            remaining ->
                                [ Ui.el [ Ui.Font.bold, Ui.width Ui.shrink ] (Ui.text (String.fromInt remaining))
                                , Ui.text " letters left"
                                ]
                        )
            , Ui.column
                [ Ui.paddingWith { left = 16, right = 8, top = 0, bottom = 16 }, Ui.spacing playerRowSpacing ]
                (case winners of
                    Just ( winners2, _ ) ->
                        leaderboardView isMobile model.highlightedPlayer winners2 shared localUser

                    Nothing ->
                        List.indexedMap
                            (\index player ->
                                playerRow
                                    localUser
                                    player.userId
                                    (index == modBy playerCount shared.turnCount)
                                    (model.highlightedPlayer == Just player.userId)
                                    (if index == modBy playerCount shared.turnCount then
                                        "'s turn (" ++ String.fromInt player.score ++ ")"

                                     else if index == modBy playerCount (shared.turnCount + 1) then
                                        " is next (" ++ String.fromInt player.score ++ ")"

                                     else
                                        " (" ++ String.fromInt player.score ++ ")"
                                    )
                            )
                            (List.Nonempty.toList shared.players)
                )
            , Ui.Lazy.lazy6 recentActionsView model.scrollPosition windowSize localUser setup actions shared
            ]


descriptionToString : Description -> String
descriptionToString description =
    case description of
        Description_PlacedWord _ { word, points, isBingo, isPremove } ->
            (if isPremove then
                " premoved "

             else
                " played "
            )
                ++ word
                ++ " (+"
                ++ String.fromInt points
                ++ (if isBingo then
                        ", bingo!"

                    else
                        ""
                   )
                ++ ")"

        Description_InvalidMove _ maybeAttemptsLeft ->
            case maybeAttemptsLeft of
                Just attemptsLeft ->
                    " played an invalid word ("
                        ++ (case OneOrGreater.toString attemptsLeft of
                                "1" ->
                                    "1 attempt left)"

                                n ->
                                    n ++ " attempts left)"
                           )

                Nothing ->
                    " played an invalid word (turn ended)"

        Description_ReplacedTray _ ->
            " swapped their tiles"

        Description_Passed _ ->
            " passed"

        Description_EndedGame _ ->
            " passed"

        Description_Joined _ ->
            " joined the game"

        Description_PremoveBlocked _ ->
            "'s premove got blocked"


{-| The player a Moves log entry is about — for a premove playing out (or being blocked) that's
the premover, not the player whose move ended the turn.
-}
descriptionUserId : Description -> Id UserId
descriptionUserId description =
    case description of
        Description_PlacedWord userId _ ->
            userId

        Description_InvalidMove userId _ ->
            userId

        Description_ReplacedTray userId ->
            userId

        Description_Passed userId ->
            userId

        Description_EndedGame userId ->
            userId

        Description_Joined userId ->
            userId

        Description_PremoveBlocked userId ->
            userId


recentActionsView : ScrollPosition -> Coord CssPixels -> LocalUser -> ValidatedSetup -> Array ActionWithTime -> Shared -> Element GameMsg
recentActionsView scrollPosition windowSize localUser setup actions shared =
    let
        log : List Description
        log =
            Array.foldl
                (\action ( shared2, acc ) ->
                    let
                        ( shared3, descriptions ) =
                            updateAction setup action shared2
                    in
                    ( shared3, List.reverse descriptions ++ acc )
                )
                ( initShared setup, [] )
                actions
                |> Tuple.second

        log2 : List (Element GameMsg)
        log2 =
            (case getWinner shared of
                Just ( _, gameEndReason ) ->
                    [ Ui.Prose.paragraph
                        [ Ui.alignTop
                        , Ui.paddingWith { left = 0, right = 0, top = 14, bottom = 6 }
                        , Ui.Font.color MyUi.font3
                        ]
                        (case gameEndReason of
                            EveryonePassed ->
                                [ Ui.text "Everyone passed and the game has ended!" ]

                            OutOfLetters userId ->
                                [ Ui.el [ Ui.Font.bold ]
                                    (Ui.text
                                        (case User.getUser userId localUser of
                                            Just user ->
                                                PersonName.toString user.name

                                            Nothing ->
                                                "<missing>"
                                        )
                                    )
                                , Ui.text " ran out of letters and the game has ended!"
                                ]
                        )
                    ]

                Nothing ->
                    case getPlayer localUser.session.userId shared of
                        Just player ->
                            case player.premove of
                                Just ( _, result, _ ) ->
                                    [ Ui.text
                                        ("You'll automatically try placing \""
                                            ++ headlineWord result.words
                                            ++ "\" when it's your turn."
                                        )
                                        |> Ui.el
                                            [ Ui.background premoveColor
                                            , Ui.Font.color MyUi.white
                                            , Ui.paddingXY 2 0
                                            , Ui.width Ui.shrink
                                            ]
                                    ]

                                Nothing ->
                                    []

                        Nothing ->
                            []
            )
                ++ List.indexedMap
                    (\index description ->
                        let
                            name : String
                            name =
                                case User.getUser (descriptionUserId description) localUser of
                                    Just user ->
                                        PersonName.toString user.name

                                    Nothing ->
                                        "<missing>"

                            moveNumber : Int
                            moveNumber =
                                List.length log - index

                            rowContent : List (Element GameMsg)
                            rowContent =
                                [ Ui.Prose.paragraph
                                    [ Ui.Font.color MyUi.font3, MyUi.noShrinking, Ui.alignTop, Ui.width Ui.shrink ]
                                    [ Ui.text (String.fromInt moveNumber ++ ". ") ]
                                , Ui.Prose.paragraph
                                    [ Ui.alignTop ]
                                    [ Ui.el [ Ui.Font.bold ] (Ui.text name)
                                    , Ui.text (descriptionToString description)
                                    ]
                                ]
                        in
                        case description of
                            Description_PlacedWord _ { word, wildcardMatches } ->
                                -- A placed word is clickable: hovering highlights the row and clicking
                                -- looks up its dictionary definition (see `PressedWordDefinition`).
                                -- Any wildcards are resolved with the fill-ins the backend found
                                -- valid, so the looked-up words are real dictionary words.
                                MyUi.rowButton
                                    (Dom.id ("wsg_moveWord_" ++ String.fromInt moveNumber))
                                    (PressedWordDefinition (definitionWords wildcardMatches word))
                                    [ Ui.Font.color MyUi.font3
                                    , Ui.spacing 8
                                    , Ui.paddingXY 4 6
                                    , Ui.rounded 4
                                    , Ui.width Ui.shrink
                                    , MyUi.htmlStyle "cursor" "pointer"
                                    , MyUi.hover (MyUi.isMobileAlt windowSize) [ Ui.Anim.fontColor MyUi.font1 ]
                                    ]
                                    rowContent

                            _ ->
                                Ui.row
                                    [ Ui.Font.color MyUi.font3, Ui.spacing 8, Ui.paddingXY 4 6 ]
                                    rowContent
                    )
                    log

        playerCount =
            List.Nonempty.length shared.players
    in
    (if List.isEmpty log2 then
        [ Ui.el [ Ui.Font.color MyUi.font3, Ui.Font.italic ] (Ui.text "No moves made yet...") ]

     else
        List.reverse log2
    )
        |> Ui.column
            [ Ui.id (Dom.idToString pastWordsContainerId)
            , Ui.Events.on "scroll" (Scroll.decodeScrollToBottom UserScrolledPastMoves scrollPosition)
            , Ui.paddingWith { left = 16, right = 16, top = 24, bottom = 16 }
            , Ui.scrollable
            ]
        |> Ui.el
            [ (tabBodyHeight windowSize setup.traySize
                - (playerRowHeight * playerCount)
                - (playerRowSpacing * (playerCount - 1))
                - lettersLeftHeight
                - 16
              )
                |> Ui.px
                |> Ui.height
            , Ui.inFront
                (Ui.el
                    [ Ui.Font.color MyUi.font3
                    , Ui.paddingWith { left = 16, right = 24, bottom = 0, top = 0 }
                    , Ui.Font.bold
                    , MyUi.noPointerEvents
                    ]
                    (Ui.el
                        [ Ui.height (Ui.px 32)
                        , Ui.backgroundGradient
                            [ Ui.Gradient.linear
                                (Ui.turns 0.5)
                                [ Ui.Gradient.px 0 MyUi.background1, Ui.Gradient.percent 100 (Ui.rgba 0 0 0 0) ]
                            , Ui.Gradient.linear
                                (Ui.turns 0.5)
                                [ Ui.Gradient.px 0 MyUi.background1, Ui.Gradient.percent 100 (Ui.rgba 0 0 0 0) ]
                            ]
                        ]
                        (Ui.text "Moves")
                    )
                )
            , case scrollPosition of
                ScrolledToBottom ->
                    Ui.noAttr

                _ ->
                    Ui.inFront
                        (Ui.el
                            [ Ui.Font.color MyUi.font3
                            , Ui.paddingWith { left = 0, right = 24, bottom = 0, top = 0 }
                            , Ui.Font.bold
                            , MyUi.noPointerEvents
                            , Ui.alignBottom
                            ]
                            (Ui.el
                                [ Ui.height (Ui.px 40)
                                , Ui.backgroundGradient
                                    [ Ui.Gradient.linear
                                        (Ui.turns 0)
                                        [ Ui.Gradient.px 0 MyUi.background1, Ui.Gradient.percent 100 (Ui.rgba 0 0 0 0) ]
                                    ]
                                ]
                                Ui.none
                            )
                        )
            ]


pastWordsContainerId : Dom.HtmlId
pastWordsContainerId =
    Dom.id "wsg_pastWords"


{-| The width of the word-definition column shown to the right of the status view on wide screens.
-}
wordDefinitionColumnWidth : number
wordDefinitionColumnWidth =
    400


{-| Whether the window is wide enough to show the word definition in its own column beside the
status view. Below this the definition is overlaid on the board instead. Mobile always overlays.
-}
wideEnoughForDefinitionColumn : Coord CssPixels -> Bool
wideEnoughForDefinitionColumn windowSize =
    not (MyUi.isMobileAlt windowSize) && Coord.xRaw windowSize >= (1200 + wordDefinitionColumnWidth)


{-| The word definition shown as a column to the right of the status view (wide screens).
-}
wordDefinitionColumn : Coord CssPixels -> ValidatedSetup -> OpenWordDefinition -> WordDefinitionData -> Element GameMsg
wordDefinitionColumn windowSize setup open data =
    Ui.column
        [ Ui.id (Dom.idToString wordDefinitionContainerId)
        , Ui.width (Ui.px wordDefinitionColumnWidth)
        , Ui.height (Ui.px (tabBodyHeight windowSize setup.traySize))
        , Ui.borderWith { left = 1, right = 0, top = 0, bottom = 0 }
        , Ui.borderColor MyUi.border1
        , Ui.background MyUi.background1
        , MyUi.noShrinking
        , Ui.clip
        ]
        [ wordDefinitionHeader open
        , Ui.el
            [ Ui.height Ui.fill, Ui.scrollable, Ui.paddingXY 16 8, Ui.heightMin 0 ]
            (wordDefinitionBody (currentDefinitionWord open) data)
        ]


{-| The word definition overlaid on top of the board (narrow screens). It only covers the board
square, not the tray below it, so the player can still grab a tile — which dismisses the popup
(see `dragStartHelper`). A close button dismisses it too.
-}
wordDefinitionOverlay : Int -> OpenWordDefinition -> WordDefinitionData -> Element GameMsg
wordDefinitionOverlay boardPx open data =
    Ui.el
        [ Ui.id (Dom.idToString wordDefinitionContainerId)
        , Ui.width (Ui.px boardPx)
        , Ui.height (Ui.px boardPx)
        , Ui.background (Ui.rgba 0 0 0 0.4)
        , Ui.padding 12
        , Ui.heightMin 0
        ]
        (Ui.column
            [ Ui.background (MyUi.colorWithAlpha 0.85 MyUi.background1)
            , Ui.rounded 8
            , Ui.border 1
            , Ui.borderColor MyUi.border1
            , Ui.height Ui.fill
            , Ui.clip
            , Ui.heightMin 0
            ]
            [ wordDefinitionHeader open
            , Ui.el
                [ Ui.height Ui.fill, Ui.scrollable, Ui.paddingXY 16 8, Ui.heightMin 0 ]
                (wordDefinitionBody (currentDefinitionWord open) data)
            ]
        )


wordDefinitionContainerId : Dom.HtmlId
wordDefinitionContainerId =
    Dom.id "wsg_wordDefinition"


{-| The title bar of a word definition popup: the currently shown word plus a close button. When
the entry's wildcards allow several words, arrows cycle through them (wrapping around at both
ends) with a "2/5"-style indicator of where in the list the shown word sits.
-}
wordDefinitionHeader : OpenWordDefinition -> Element GameMsg
wordDefinitionHeader open =
    let
        wordCount : Int
        wordCount =
            List.Nonempty.length open.words
    in
    Ui.row
        [ Ui.spacing 8
        , Ui.paddingWith { left = 16, right = 0, top = 0, bottom = 0 }
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border1
        , Ui.Font.color MyUi.font1
        , Ui.height (Ui.px 42)
        , MyUi.noShrinking
        , Ui.contentCenterY
        , Ui.background MyUi.background1
        ]
        [ Ui.el
            [ Ui.Font.bold, Ui.Font.size 18, Ui.width Ui.shrink, MyUi.monospace, Ui.Font.letterSpacing 1.5 ]
            (Ui.text (currentDefinitionWord open))
        , if wordCount > 1 then
            let
                total =
                    String.fromInt wordCount

                current =
                    String.fromInt (open.index + 1)

                diff =
                    String.length total - String.length current
            in
            Ui.row
                [ Ui.width Ui.shrink, Ui.contentCenterY ]
                [ wordDefinitionArrow
                    (Dom.id "wsg_previousWordDefinition")
                    PressedPreviousWordDefinition
                    "Previous word"
                    (Icons.arrowLeft 16)
                , Ui.row
                    [ Ui.Font.size 14, Ui.Font.color MyUi.font3, Ui.width Ui.shrink, Ui.Font.noWrap ]
                    [ Ui.el [ Ui.opacity 0.5 ] (Ui.text (String.repeat diff "0"))
                    , Ui.text (current ++ "/" ++ total)
                    ]
                , wordDefinitionArrow
                    (Dom.id "wsg_nextWordDefinition")
                    PressedNextWordDefinition
                    "Next word"
                    (Icons.arrowRight 16)
                ]

          else
            Ui.none
        , Ui.el [] Ui.none
        , MyUi.elButton
            (Dom.id "wsg_closeWordDefinition")
            PressedCloseWordDefinition
            [ Ui.width (Ui.px 42)
            , Ui.height Ui.fill
            , Ui.alignRight
            , Ui.contentCenterX
            , Ui.contentCenterY
            , Ui.rounded 4
            , Ui.Font.color MyUi.font3
            , Ui.Accessibility.description "Close word definition"
            , MyUi.hover False [ Ui.Anim.fontColor MyUi.font1 ]
            ]
            (Ui.html Icons.x)
        ]


{-| One of the arrow buttons that cycle the definition popup through its candidate words.
-}
wordDefinitionArrow : Dom.HtmlId -> GameMsg -> String -> Html.Html GameMsg -> Element GameMsg
wordDefinitionArrow htmlId onPress label icon =
    MyUi.elButton
        htmlId
        onPress
        [ Ui.width (Ui.px 32)
        , Ui.height (Ui.px 42)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.rounded 4
        , Ui.Font.color MyUi.font3
        , Ui.Accessibility.description label
        , MyUi.hover False [ Ui.Anim.fontColor MyUi.font1 ]
        ]
        (Ui.html icon)


{-| The body of a word definition popup, which depends on how far the lookup has got.
-}
wordDefinitionBody : String -> WordDefinitionData -> Element GameMsg
wordDefinitionBody word data =
    case data of
        WordDefinition_Loading ->
            Ui.el
                [ Ui.Font.color MyUi.font3
                , Ui.Font.italic
                , Ui.Anim.intro (Ui.Anim.ms 200) { start = [ Ui.Anim.opacity 0 ], to = [ Ui.Anim.opacity 1 ] }
                ]
                (Ui.text "Loading definition...")

        WordDefinition_SwedishUnsupported ->
            Ui.el
                [ Ui.Font.color MyUi.font3 ]
                (Ui.text "Swedish dictionary definitions not supported")

        WordDefinition_NotFound ->
            Ui.column
                [ Ui.Font.color MyUi.font3, Ui.height Ui.fill ]
                [ Ui.text ("No definition found for \"" ++ word ++ "\".")
                , definitionCredits
                ]

        WordDefinition_Loaded entries ->
            Ui.column
                [ Ui.spacing 16, Ui.height Ui.fill ]
                (List.map wordDefinitionEntryView entries
                    ++ [ definitionCredits
                       ]
                )


definitionCredits : Element msg
definitionCredits =
    Ui.Prose.paragraph
        [ Ui.alignBottom
        , Ui.Font.size 14
        , Ui.paddingWith { left = 0, right = 0, top = 24, bottom = 16 }
        , Ui.Font.color MyUi.font3
        ]
        [ Ui.text "Dictionary provided by "
        , Ui.el
            [ Ui.linkNewTab "https://dictionaryapi.dev/", Ui.Font.noWrap ]
            (Ui.text "https://dictionaryapi.dev/")
        ]


wordDefinitionEntryView : DictEntry -> Element GameMsg
wordDefinitionEntryView entry =
    let
        shouldNumber =
            List.length entry.definitions > 1
    in
    Ui.column
        [ Ui.spacing 6 ]
        (Ui.el [ Ui.Font.bold, Ui.Font.italic, Ui.Font.color MyUi.font3 ] (Ui.text entry.partOfSpeech)
            :: List.indexedMap
                (\index def ->
                    Ui.row
                        [ Ui.spacing 8, Ui.contentTop ]
                        [ if shouldNumber then
                            Ui.el
                                [ Ui.Font.bold, Ui.width Ui.shrink, MyUi.noShrinking ]
                                (Ui.text (String.fromInt (index + 1) ++ "."))

                          else
                            Ui.none
                        , Ui.text def
                        ]
                )
                entry.definitions
        )


{-| Replay the action list to work out which player placed each committed tile on the board. Each
`Description_PlacedWord` an action produces attributes the cells it placed — that covers premoved
words too, which get attributed to the premover (a placement rejected by the backend produces an
invalid-move description instead, leaving the board unchanged, so it's skipped). Used to highlight
one player's letters when their name is clicked (see `statusView`).
-}
tileOwners : ValidatedSetup -> Array ActionWithTime -> SeqDict ( Int, Int ) (Id UserId)
tileOwners setup actions =
    Array.foldl
        (\action ( shared, owners ) ->
            let
                ( shared2, descriptions ) =
                    updateAction setup action shared
            in
            ( shared2
            , List.foldl
                (\description owners2 ->
                    case description of
                        Description_PlacedWord userId { placedCells } ->
                            List.foldl
                                (\cell acc -> SeqDict.insert cell userId acc)
                                owners2
                                placedCells

                        _ ->
                            owners2
                )
                owners
                descriptions
            )
        )
        ( initShared setup, SeqDict.empty )
        actions
        |> Tuple.second


{-| The word a placement formed that uses the most of the newly placed tiles, rendered as uppercase
text, used as the headline word in an action description. Ties are broken by word length so the
longer word wins.
-}
headlineWord : List { letters : List LetterOrWildcard, placedCount : Int } -> String
headlineWord words =
    words
        |> List.sortBy headlineOrder
        |> List.head
        |> Maybe.map (\a -> a.letters |> letterOrWildcardsToString)
        |> Maybe.withDefault "a word"


{-| The sort key that puts a placement's headline word first. Shared between `headlineWord` and
`validatePlacement` so the wildcard fill-ins stored in `IsValid` belong to the same word the Moves
log displays.
-}
headlineOrder : { letters : List LetterOrWildcard, placedCount : Int } -> ( Int, Int )
headlineOrder word =
    ( negate word.placedCount, negate (List.length word.letters) )


{-| Every dictionary word a Moves log entry can stand for: the rendered word (see
`letterOrWildcardsToString`) with its underscores resolved by each of the valid wildcard fill-ins,
so e.g. "H\_P" with matches { "O", "I" } gives HIP and HOP. When there are no fill-ins to draw
from (backend validation hasn't arrived yet) the word is the only candidate, unchanged.
-}
definitionWords : Set String -> String -> Nonempty String
definitionWords wildcardMatches word =
    case List.map (\fillIns -> resolveWildcards fillIns word) (Set.toList wildcardMatches) of
        first :: rest ->
            Nonempty first rest

        [] ->
            Nonempty word []


{-| Fill in the underscores of a rendered word with one wildcard fill-in (one character per
underscore, in order), so e.g. "H\_P" with "O" becomes "HOP".
-}
resolveWildcards : String -> String -> String
resolveWildcards fillIns word =
    String.foldl
        (\char ( remaining, resolved ) ->
            case ( char, remaining ) of
                ( '_', fillIn :: rest ) ->
                    ( rest, resolved ++ String.fromChar fillIn )

                _ ->
                    ( remaining, resolved ++ String.fromChar char )
        )
        ( String.toList fillIns, "" )
        word
        |> Tuple.second


{-| Render placed tiles as uppercase text, showing a wildcard as an underscore since the board
doesn't record which letter it stands for.
-}
letterOrWildcardsToString : List LetterOrWildcard -> String
letterOrWildcardsToString letters =
    List.map
        (\letterOrWildcard ->
            case letterOrWildcard of
                Letter (LetterChar letter) ->
                    String.fromChar letter

                Wildcard ->
                    "_"
        )
        letters
        |> String.concat


trayHeight : OneOrGreater -> Coord CssPixels -> Int
trayHeight traySize windowSize =
    trayTileSize traySize windowSize |> round


boardView :
    Time.Posix
    -> Coord CssPixels
    -> Maybe (NonemptyDict Int Touch)
    -> LocalUser
    -> ValidatedSetup
    -> Shared
    -> Set ( Int, Int )
    -> GameData
    -> Element GameMsg
boardView currentTime windowSize maybeDragging localUser setup shared highlightedCells model =
    let
        cellSize2 : Int
        cellSize2 =
            cellSize setup.traySize windowSize

        zoom : Maybe { zoomedCellSize : Int, translate : Coord CssPixels }
        zoom =
            boardZoom currentTime setup.traySize windowSize model

        -- The zoomed-in cell size, i.e. how big a board cell is drawn once the mobile zoom is
        -- applied (the same as `cellSize2` when there's no zoom).
        zoomedCellSize : Int
        zoomedCellSize =
            case zoom of
                Just z ->
                    z.zoomedCellSize

                Nothing ->
                    cellSize2

        -- How far the zoomed board content is shifted (in board-local coordinates) so the visible
        -- window is centred on the centroid of the placed tiles (clamped to the board edges).
        boardTranslate : Coord CssPixels
        boardTranslate =
            case zoom of
                Just z ->
                    z.translate

                Nothing ->
                    Coord.origin

        animatingCellSet : Set ( Int, Int )
        animatingCellSet =
            animatingCells currentTime shared

        maybePlayer : Maybe Player
        maybePlayer =
            getPlayer currentUserId shared

        boardTiles : List (Ui.Attribute GameMsg)
        boardTiles =
            SeqDict.foldl
                (\( x, y ) letter list ->
                    if Set.member ( x, y ) animatingCellSet then
                        -- This tile is being animated into place, so the animation layer draws it.
                        list

                    else
                        let
                            p : { pos : Coord CssPixels, size : Int }
                            p =
                                project boardTranslate zoomedCellSize x y
                        in
                        boardTileInFront
                            setup
                            (Set.member ( x, y ) highlightedCells)
                            p.size
                            p.pos
                            letter
                            :: list
                )
                []
                shared.board

        currentUserId =
            localUser.session.userId

        isPreviousPlayer : Bool
        isPreviousPlayer =
            List.Nonempty.get (shared.turnCount - 1) shared.players |> .userId |> (==) currentUserId

        animatedTiles : List (Ui.Attribute GameMsg)
        animatedTiles =
            case shared.lastPlacement of
                Just placement ->
                    if isAnimating currentTime shared then
                        let
                            elapsed : Float
                            elapsed =
                                elapsedMs currentTime placement.startTime

                            tileCount : Int
                            tileCount =
                                List.length placement.cells
                        in
                        List.indexedMap
                            (\index ( ( x, y ), letterOrWildcard ) ->
                                case animatedTilePlacement isPreviousPlayer elapsed placement.isValid tileCount index of
                                    Just { progress, red } ->
                                        let
                                            p : { pos : Coord CssPixels, size : Int }
                                            p =
                                                project boardTranslate zoomedCellSize x y

                                            startX : Int
                                            startX =
                                                if red && isPreviousPlayer then
                                                    -p.size + (cellSize2 * gridSize) // 2

                                                else
                                                    -p.size

                                            startY : Int
                                            startY =
                                                if red && isPreviousPlayer then
                                                    cellSize2 * gridSize

                                                else
                                                    -p.size

                                            destX : Int
                                            destX =
                                                Coord.xRaw p.pos

                                            destY : Int
                                            destY =
                                                Coord.yRaw p.pos
                                        in
                                        animatedTileInFront
                                            setup
                                            p.size
                                            (Coord.xy
                                                (round (toFloat startX + progress * toFloat (destX - startX)))
                                                (round (toFloat startY + progress * toFloat (destY - startY)))
                                            )
                                            red
                                            letterOrWildcard
                                            |> Just

                                    Nothing ->
                                        Nothing
                            )
                            placement.cells
                            |> List.filterMap identity

                    else
                        []

                Nothing ->
                    []

        -- The player's held tiles, split into those resting on the board (drawn in the zoomed,
        -- clipped board layer) and those in the tray or being dragged (drawn unzoomed on top).
        ( boardHeldTiles, trayHeldTiles ) =
            List.map2
                Tuple.pair
                (Array.toList model.tiles)
                (case maybePlayer of
                    Just player ->
                        IdArray.toList player.tray

                    Nothing ->
                        []
                )
                |> List.indexedMap Tuple.pair
                |> List.foldr
                    (\( index, ( tile, letter ) ) ( boardAcc, trayAcc ) ->
                        case ( maybeDragging, Dragging index == model.dragging ) of
                            ( Just dragging2, True ) ->
                                let
                                    center : Coord CssPixels
                                    center =
                                        Touch.touchCentroid dragging2
                                in
                                ( boardAcc
                                , tileInFront
                                    setup
                                    currentTime
                                    tile.createdAt
                                    False
                                    zoomedCellSize
                                    (Coord.xy
                                        (Coord.xRaw center - zoomedCellSize // 2)
                                        (Coord.yRaw center - zoomedCellSize // 2)
                                    )
                                    letter
                                    :: trayAcc
                                )

                            _ ->
                                case tile.position of
                                    TileInTray trayIndex shiftAnimation ->
                                        ( boardAcc
                                        , tileInFront
                                            setup
                                            currentTime
                                            tile.createdAt
                                            False
                                            (trayTileSize setup.traySize windowSize |> round)
                                            (animatedTrayTilePos setup windowSize currentTime trayIndex shiftAnimation)
                                            letter
                                            :: trayAcc
                                        )

                                    TileOnBoard ( x, y ) _ ->
                                        let
                                            p : { pos : Coord CssPixels, size : Int }
                                            p =
                                                project boardTranslate zoomedCellSize x y
                                        in
                                        ( tileInFront
                                            setup
                                            currentTime
                                            tile.createdAt
                                            (case maybePlayer of
                                                Just player ->
                                                    case player.premove of
                                                        Just ( _, result, _ ) ->
                                                            List.any
                                                                (\( ( xA, yA ), _ ) -> xA == x && yA == y)
                                                                result.placedCells

                                                        Nothing ->
                                                            False

                                                Nothing ->
                                                    False
                                            )
                                            p.size
                                            p.pos
                                            letter
                                            :: boardAcc
                                        , trayAcc
                                        )
                    )
                    ( [], [] )

        dragHighlight : Ui.Attribute GameMsg
        dragHighlight =
            case ( model.dragging, maybeDragging ) of
                ( Dragging _, Just dragging2 ) ->
                    case boardCellAtPosition currentTime windowSize setup model (Touch.touchCentroid dragging2) of
                        Just ( x, y ) ->
                            if
                                SeqDict.member ( x, y ) shared.board
                                    || Array.Extra.any
                                        (\tile ->
                                            case tile.position of
                                                TileOnBoard pos _ ->
                                                    pos == ( x, y )

                                                TileInTray _ _ ->
                                                    False
                                        )
                                        model.tiles
                            then
                                Ui.noAttr

                            else
                                let
                                    p : { pos : Coord CssPixels, size : Int }
                                    p =
                                        project boardTranslate zoomedCellSize x y
                                in
                                Ui.inFront
                                    (Ui.el
                                        [ Ui.borderColor (Ui.rgb 0 200 255)
                                        , Ui.border 3
                                        , Ui.width (Ui.px p.size)
                                        , Ui.height (Ui.px p.size)
                                        , Ui.move { x = Coord.xRaw p.pos, y = Coord.yRaw p.pos, z = 0 }
                                        , MyUi.noPointerEvents
                                        ]
                                        Ui.none
                                    )

                        Nothing ->
                            Ui.noAttr

                _ ->
                    Ui.noAttr

        selectedHighlight : Ui.Attribute GameMsg
        selectedHighlight =
            case model.selectedCell of
                Just ( x, y ) ->
                    let
                        p : { pos : Coord CssPixels, size : Int }
                        p =
                            project boardTranslate zoomedCellSize x y
                    in
                    Ui.inFront
                        (Ui.el
                            [ Ui.borderColor (Ui.rgb 0 200 255)
                            , Ui.border 4
                            , Ui.width (Ui.px p.size)
                            , Ui.height (Ui.px p.size)
                            , Ui.move { x = Coord.xRaw p.pos, y = Coord.yRaw p.pos, z = 0 }
                            , MyUi.noPointerEvents
                            ]
                            Ui.none
                        )

                Nothing ->
                    Ui.noAttr

        -- A small send-icon button next to every valid word the player has placed. Hidden while a
        -- tile is being dragged, when it isn't the player's turn, or once the game is over.
        lineButtons : List (Ui.Attribute GameMsg)
        lineButtons =
            case ( model.dragging, getWinner shared, isPlayerTurn currentUserId shared ) of
                ( NotDragging, Nothing, JoinedAndItsTheirTurn ) ->
                    submitLineButtons
                        "wordSpellingGame_submitLine_"
                        MyUi.buttonBackground
                        PressedSubmitWord
                        boardTranslate
                        zoomedCellSize
                        currentUserId
                        shared
                        model

                ( NotDragging, Nothing, Joined ) ->
                    case maybePlayer of
                        Just player ->
                            case player.premove of
                                Just _ ->
                                    []

                                Nothing ->
                                    submitLineButtons
                                        "wsg_submitPremove_"
                                        premoveColor
                                        PressedSubmitPremove
                                        boardTranslate
                                        zoomedCellSize
                                        currentUserId
                                        shared
                                        model

                        Nothing ->
                            []

                _ ->
                    []

        trayHeight2 : Int
        trayHeight2 =
            trayHeight setup.traySize windowSize

        trayWidth : Int
        trayWidth =
            Coord.xRaw (trayTilePos setup.traySize windowSize (TrayIndex (OneOrGreater.toInt setup.traySize))) - trayTileSpacing - trayX windowSize

        -- A tray-tile sized button next to the tray that replaces the player's tray with fresh
        -- letters. It's greyed out and does nothing once the letter bag is empty (there's nothing
        -- to draw); the pass/end button in `statusView` takes over then.
        replaceTrayButton : Ui.Attribute GameMsg
        replaceTrayButton =
            let
                pos : Coord CssPixels
                pos =
                    trayTilePos setup.traySize windowSize (TrayIndex (OneOrGreater.toInt setup.traySize))

                buttonSize : Int
                buttonSize =
                    round (trayTileSize setup.traySize windowSize)

                attributes : List (Ui.Attribute GameMsg)
                attributes =
                    [ Ui.move { x = Coord.xRaw pos, y = Coord.yRaw pos, z = 0 }
                    , Ui.width (Ui.px buttonSize)
                    , Ui.height (Ui.px buttonSize)
                    , Ui.rounded (buttonSize // 6)
                    , Ui.contentCenterX
                    , Ui.contentCenterY
                    , Ui.Font.color MyUi.white
                    , Ui.background MyUi.buttonBackground
                    , Ui.Font.center
                    , Ui.Font.bold
                    ]
            in
            Ui.inFront
                (case isPlayerTurn localUser.session.userId shared of
                    JoinedAndItsTheirTurn ->
                        case getWinner shared of
                            Just _ ->
                                Ui.none

                            Nothing ->
                                case passBehavior setup shared of
                                    ShouldReplaceTray ->
                                        MyUi.elButton (Dom.id "wordSpellingGame_replaceTray") PressedReplaceTrayOrPass attributes (Ui.html Icons.recycle)

                                    ShouldPass ->
                                        MyUi.elButton (Dom.id "wordSpellingGame_passOrEndTurn") PressedReplaceTrayOrPass attributes (Ui.text "Pass")

                                    ShouldEndGame ->
                                        MyUi.elButton (Dom.id "wordSpellingGame_passOrEndTurn") PressedReplaceTrayOrPass attributes (Ui.text "End game")

                    Joined ->
                        Ui.none

                    NotJoined ->
                        if canJoin shared then
                            MyUi.elButton (Dom.id "wordSpellingGame_joinGame") PressedJoinGame attributes (Ui.text "Join")

                        else
                            Ui.none
                )

        boardPx : Int
        boardPx =
            gridSize * cellSize2

        -- A large clear button pinned to a top corner of the board viewport, shown only while the
        -- player has tiles resting on the board. It sits in whichever top corner is farther from the
        -- tiles being placed, so it stays out of the way, and is drawn bigger than a grid cell to
        -- stand out. Clicking it returns every placed tile to the tray (see `PressedClearBoard`).
        clearButton : Ui.Attribute GameMsg
        clearButton =
            let
                placed : List ( ( Int, Int ), LetterOrWildcard )
                placed =
                    placedTiles currentUserId shared model
            in
            case ( getWinner shared, placed ) of
                ( Nothing, _ :: _ ) ->
                    let
                        buttonSize : Int
                        buttonSize =
                            round (toFloat cellSize2 * 1.6)

                        -- Centre of each placed tile in on-screen viewport coordinates (so the zoom is
                        -- accounted for), used to decide which top corner is farther away.
                        centers : List ( Float, Float )
                        centers =
                            List.map
                                (\( ( x, y ), _ ) ->
                                    let
                                        p : { pos : Coord CssPixels, size : Int }
                                        p =
                                            project boardTranslate zoomedCellSize x y
                                    in
                                    ( toFloat (Coord.xRaw p.pos) + toFloat p.size / 2
                                    , toFloat (Coord.yRaw p.pos) + toFloat p.size / 2
                                    )
                                )
                                placed

                        count : Float
                        count =
                            toFloat (List.length placed)

                        centroidX : Float
                        centroidX =
                            List.sum (List.map Tuple.first centers) / count

                        centroidY : Float
                        centroidY =
                            List.sum (List.map Tuple.second centers) / count

                        distanceSquaredTo : Float -> Float
                        distanceSquaredTo cornerX =
                            (centroidX - cornerX) ^ 2 + centroidY ^ 2

                        buttonX : Int
                        buttonX =
                            if distanceSquaredTo (toFloat boardPx) > distanceSquaredTo 0 then
                                boardPx - buttonSize

                            else
                                0
                    in
                    Ui.inFront
                        (MyUi.elButton (Dom.id "wordSpellingGame_clearBoard")
                            PressedClearBoard
                            [ Ui.move { x = buttonX, y = 0, z = 0 }
                            , Ui.width (Ui.px buttonSize)
                            , Ui.height (Ui.px buttonSize)
                            , Ui.background
                                (case maybePlayer of
                                    Just player ->
                                        case player.premove of
                                            Just _ ->
                                                premoveColor

                                            Nothing ->
                                                MyUi.buttonBackground

                                    Nothing ->
                                        MyUi.buttonBackground
                                )
                            , Ui.rounded (buttonSize // 5)
                            , Ui.borderColor MyUi.white
                            , Ui.border 2
                            , Ui.contentCenterX
                            , Ui.contentCenterY
                            , Ui.Font.color MyUi.white
                            ]
                            (Ui.html Icons.delete)
                        )

                _ ->
                    Ui.noAttr

        -- The zoomed board: grid background plus the tiles/highlights that live on the board,
        -- clipped to the board's fixed on-screen square so the zoomed-in content doesn't spill over
        -- the tray or grow the viewport.
        boardLayer : Element GameMsg
        boardLayer =
            Ui.el
                (Ui.width (Ui.px boardPx)
                    :: Ui.height (Ui.px boardPx)
                    :: Ui.clip
                    -- elm-ui's base element class sets `min-height: min-content`, and Chrome (unlike
                    -- Firefox and Safari) lets that beat the explicit `height` above. When the board is
                    -- zoomed in, the in-flow background grid is taller than the board square, so on
                    -- Chrome this element itself grew to the grid's full height and `Ui.clip` clipped at
                    -- the enlarged box, letting the zoomed board spill out the bottom (only the bottom:
                    -- elm-ui resets `min-width` but not `min-height`). Resetting min-height keeps the
                    -- element at boardPx so the clip actually cuts the zoomed content off.
                    :: MyUi.htmlStyle "min-height" "0"
                    :: clearButton
                    :: lineButtons
                    ++ boardTiles
                    ++ animatedTiles
                    ++ boardHeldTiles
                    ++ [ selectedHighlight, dragHighlight ]
                )
                (Ui.el
                    [ Ui.move { x = Coord.xRaw boardTranslate, y = Coord.yRaw boardTranslate, z = 0 } ]
                    (Ui.Lazy.lazy boardViewBackground zoomedCellSize)
                )

        -- The tray tiles, tray background and any tile currently being dragged, drawn unzoomed on
        -- top of the board. Positions are in screen coordinates, so the layer is shifted back to the
        -- board's top-left corner.
        trayLayer : Ui.Attribute GameMsg
        trayLayer =
            Ui.inFront
                (Ui.el
                    (Ui.move { x = -(boardX windowSize), y = -boardY, z = 0 }
                        :: replaceTrayButton
                        :: trayHeldTiles
                        ++ [ Ui.inFront
                                (Ui.el
                                    [ Ui.background (Ui.rgb 119 97 97)
                                    , Ui.move { x = trayX windowSize, y = trayY setup.traySize windowSize, z = 0 }
                                    , Ui.width (Ui.px trayWidth)
                                    , Ui.height (Ui.px (trayHeight2 + 4))
                                    ]
                                    Ui.none
                                )
                           ]
                    )
                    Ui.none
                )
    in
    Ui.el
        [ Ui.width (Ui.px boardPx)
        , Ui.height (Ui.px (boardPx + trayHeight2))
        , Ui.pointer
        , trayLayer
        , MyUi.htmlStyle "user-select" "none"
        ]
        boardLayer


premoveColor : Ui.Color
premoveColor =
    Ui.rgb 98 43 227


submitLineButtons :
    String
    -> Ui.Color
    -> ({ start : ( Int, Int ), isVertical : Bool, letters : Nonempty LetterOrWildcard } -> msg)
    -> Coord CssPixels
    -> Int
    -> Id UserId
    -> Shared
    -> GameData
    -> List (Ui.Attribute msg)
submitLineButtons htmlIdPrefix color onPress boardTranslate zoomedCellSize currentUserId shared model =
    submittableLines currentUserId shared model
        |> List.map
            (\line ->
                let
                    ( bx, by ) =
                        line.buttonCell

                    p : { pos : Coord CssPixels, size : Int }
                    p =
                        project boardTranslate zoomedCellSize bx by

                    idString : String
                    idString =
                        htmlIdPrefix
                            ++ (if line.placedWord.isVertical then
                                    "v"

                                else
                                    "h"
                               )
                            ++ "_"
                            ++ String.fromInt (Tuple.first line.placedWord.start)
                            ++ "_"
                            ++ String.fromInt (Tuple.second line.placedWord.start)
                in
                MyUi.elButton (Dom.id idString)
                    (onPress line.placedWord)
                    [ Ui.move { x = Coord.xRaw p.pos, y = Coord.yRaw p.pos, z = 0 }
                    , Ui.width (Ui.px p.size)
                    , Ui.height (Ui.px p.size)
                    , Ui.background color
                    , Ui.rounded (p.size // 4)
                    , Ui.borderColor MyUi.white
                    , Ui.border 2
                    , Ui.contentCenterX
                    , Ui.contentCenterY
                    , Ui.Font.color MyUi.white
                    ]
                    (Ui.html Icons.sendMessage)
                    |> Ui.inFront
            )


{-| A board cell's top-left position (in board-local coordinates, relative to the board's top-left corner) and drawn size, with the mobile zoom applied.
-}
project : Coord CssPixels -> Int -> Int -> Int -> { pos : Coord CssPixels, size : Int }
project boardTranslate zoomedCellSize x y =
    { pos =
        Coord.xy
            (Coord.xRaw boardTranslate + zoomedCellSize * x)
            (Coord.yRaw boardTranslate + zoomedCellSize * y)
    , size = zoomedCellSize
    }


tileInFront : ValidatedSetup -> Time.Posix -> Time.Posix -> Bool -> Int -> Coord CssPixels -> LetterOrWildcard -> Ui.Attribute GameMsg
tileInFront setup currentTime createdAt premove cellSize2 offset letterOrWildcard =
    let
        fade : { opacity : Float, drift : Float }
        fade =
            tileFade currentTime createdAt
    in
    Ui.inFront
        (Ui.el
            [ Ui.background
                (if premove then
                    premoveColor

                 else
                    Ui.rgb 240 220 130
                )
            , Ui.width (Ui.px (cellSize2 - 1))
            , Ui.height (Ui.px (cellSize2 - 1))
            , Ui.contentCenterX
            , Ui.contentCenterY
            , toFloat cellSize2 * 0.7 |> ceiling |> Ui.Font.size
            , Ui.Font.bold
            , Ui.move
                { x = Coord.xRaw offset
                , y = Coord.yRaw offset - round (fade.drift * tileFadeDrift * toFloat cellSize2)
                , z = 0
                }
            , Ui.Font.color
                (if premove then
                    MyUi.white

                 else
                    MyUi.black
                )
            , Ui.opacity fade.opacity
            , MyUi.noPointerEvents
            , tileScoreView setup cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


boardTileInFront : ValidatedSetup -> Bool -> Int -> Coord CssPixels -> LetterOrWildcard -> Ui.Attribute GameMsg
boardTileInFront setup highlight cellSize2 offset letterOrWildcard =
    Ui.inFront
        (Ui.el
            [ Ui.background
                (if highlight then
                    MyUi.replyToColor

                 else
                    Ui.rgb 186 171 103
                )
            , Ui.width (Ui.px (cellSize2 - 1))
            , Ui.height (Ui.px (cellSize2 - 1))
            , Ui.contentCenterX
            , Ui.contentCenterY
            , toFloat cellSize2 * 0.7 |> ceiling |> Ui.Font.size
            , Ui.Font.bold
            , Ui.move { x = Coord.xRaw offset, y = Coord.yRaw offset, z = 0 }
            , Ui.Font.color
                (if highlight then
                    MyUi.white

                 else
                    MyUi.black
                )
            , MyUi.noPointerEvents
            , tileScoreView setup cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


tileScoreView : ValidatedSetup -> Int -> LetterOrWildcard -> Ui.Attribute msg
tileScoreView setup cellSize2 letterOrWildcard =
    Ui.text
        (case letterOrWildcard of
            Letter letter ->
                letterValue setup letter |> String.fromInt

            Wildcard ->
                ""
        )
        |> Ui.el
            [ toFloat cellSize2 * 0.3 |> ceiling |> Ui.Font.size
            , Ui.alignBottom
            , Ui.alignRight
            , Ui.move { x = -2, y = 0, z = 0 }
            ]
        |> Ui.inFront


{-| A tile drawn by the placement animation. It looks like a committed board tile, except a
rejected tile (on its way back off the board) is shown in red.
-}
animatedTileInFront : ValidatedSetup -> Int -> Coord CssPixels -> Bool -> LetterOrWildcard -> Ui.Attribute GameMsg
animatedTileInFront setup cellSize2 offset red letterOrWildcard =
    Ui.inFront
        (Ui.el
            [ Ui.background
                (if red then
                    Ui.rgb 214 69 69

                 else
                    Ui.rgb 186 171 103
                )
            , Ui.width (Ui.px (cellSize2 - 1))
            , Ui.height (Ui.px (cellSize2 - 1))
            , Ui.contentCenterX
            , Ui.contentCenterY
            , toFloat cellSize2 * 0.7 |> ceiling |> Ui.Font.size
            , Ui.Font.bold
            , Ui.move { x = Coord.xRaw offset, y = Coord.yRaw offset, z = 0 }
            , Ui.Font.color
                (if red then
                    MyUi.white

                 else
                    MyUi.black
                )
            , MyUi.noPointerEvents
            , tileScoreView setup cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


letterOrWildcardText : LetterOrWildcard -> String
letterOrWildcardText letterOrWildcard =
    case letterOrWildcard of
        Letter (LetterChar letter) ->
            String.fromChar letter

        Wildcard ->
            " "


boardViewBackground : Int -> Element GameMsg
boardViewBackground cellSize2 =
    List.map
        (\y ->
            Ui.row
                []
                (List.map (\x -> cellView cellSize2 ( x, y )) (List.range 0 (gridSize - 1)))
        )
        (List.range 0 (gridSize - 1))
        |> Ui.column [ MyUi.noPointerEvents ]


statusHeight : number
statusHeight =
    70


tabBodyHeight : Coord CssPixels -> OneOrGreater -> Int
tabBodyHeight windowSize traySize =
    cellSize traySize windowSize
        * gridSize
        + trayHeight traySize windowSize
        + (if MyUi.isMobileAlt windowSize then
            statusHeight

           else
            0
          )
        + 10


cellSize : OneOrGreater -> Coord CssPixels -> Int
cellSize traySize windowSize =
    let
        availableSize : Int
        availableSize =
            min
                (round (toFloat (Coord.yRaw windowSize) * 0.7)
                    - trayHeight traySize windowSize
                    - (if MyUi.isMobileAlt windowSize then
                        statusHeight

                       else
                        0
                      )
                )
                (Coord.xRaw windowSize)
    in
    min 30 (availableSize // gridSize)


cellView : Int -> ( Int, Int ) -> Element GameMsg
cellView cellSize2 position =
    let
        maybeBonus : Maybe BonusCells
        maybeBonus =
            SeqDict.get position bonusCells
    in
    Ui.el
        [ case maybeBonus of
            Just specialCell ->
                Ui.background (bonusCellColor specialCell)

            Nothing ->
                Ui.background (Ui.rgb 250 250 250)
        , Ui.width (Ui.px cellSize2)
        , Ui.height (Ui.px cellSize2)

        -- The center cell's star label has a line box taller than the cell (font-size 0.8×cell with
        -- inherited line-height 1.4). On Chrome, elm-ui's `min-height: min-content` beats the explicit
        -- `height` above, so that one cell — and with it the whole center row — grew taller than the
        -- other rows, showing two horizontal strips of page background across the board. Resetting
        -- min-height keeps every cell exactly cellSize2 tall.
        , MyUi.htmlStyle "min-height" "0"
        , Ui.borderWith { left = 0, right = 1, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.inputBorder
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        (case maybeBonus of
            Just bonus ->
                Ui.el
                    [ Ui.centerX
                    , Ui.centerY
                    , (case bonus of
                        CenterCell ->
                            round (toFloat cellSize2 * 0.8)

                        _ ->
                            round (toFloat cellSize2 * 0.5)
                      )
                        |> Ui.Font.size
                    , Ui.Font.color (bonusCellColor bonus |> Color.Manipulate.darken 0.3)
                    , Ui.Font.bold
                    ]
                    (Ui.text (bonusCellLabel bonus))

            Nothing ->
                Ui.none
        )


type BonusCells
    = DoubleWord
    | TripleWord
    | DoubleLetter
    | TripleLetter
    | CenterCell


bonusCellColor : BonusCells -> Ui.Color
bonusCellColor bonus =
    case bonus of
        DoubleWord ->
            Ui.rgb 225 163 163

        TripleWord ->
            Ui.rgb 228 46 46

        DoubleLetter ->
            Ui.rgb 123 208 232

        TripleLetter ->
            Ui.rgb 24 116 191

        CenterCell ->
            Ui.rgb 241 154 154


bonusCellLabel : BonusCells -> String
bonusCellLabel bonus =
    case bonus of
        DoubleWord ->
            "DW"

        TripleWord ->
            "TW"

        DoubleLetter ->
            "DL"

        TripleLetter ->
            "TL"

        CenterCell ->
            "★"


bonusCells : SeqDict ( Int, Int ) BonusCells
bonusCells =
    ( ( 7, 7 ), CenterCell )
        :: List.map (\position -> ( position, TripleWord )) tripleWordCells
        ++ List.map (\position -> ( position, DoubleWord )) doubleWordCells
        ++ List.map (\position -> ( position, TripleLetter )) tripleLetterCells
        ++ List.map (\position -> ( position, DoubleLetter )) doubleLetterCells
        |> SeqDict.fromList


tripleWordCells : List ( Int, Int )
tripleWordCells =
    [ ( 0, 0 )
    , ( 7, 0 )
    , ( 14, 0 )
    , ( 0, 7 )
    , ( 14, 7 )
    , ( 0, 14 )
    , ( 7, 14 )
    , ( 14, 14 )
    ]


doubleWordCells : List ( Int, Int )
doubleWordCells =
    [ ( 1, 1 )
    , ( 2, 2 )
    , ( 3, 3 )
    , ( 4, 4 )
    , ( 13, 1 )
    , ( 12, 2 )
    , ( 11, 3 )
    , ( 10, 4 )
    , ( 1, 13 )
    , ( 2, 12 )
    , ( 3, 11 )
    , ( 4, 10 )
    , ( 13, 13 )
    , ( 12, 12 )
    , ( 11, 11 )
    , ( 10, 10 )
    ]


tripleLetterCells : List ( Int, Int )
tripleLetterCells =
    [ ( 5, 1 )
    , ( 9, 1 )
    , ( 1, 5 )
    , ( 5, 5 )
    , ( 9, 5 )
    , ( 13, 5 )
    , ( 1, 9 )
    , ( 5, 9 )
    , ( 9, 9 )
    , ( 13, 9 )
    , ( 5, 13 )
    , ( 9, 13 )
    ]


doubleLetterCells : List ( Int, Int )
doubleLetterCells =
    [ ( 3, 0 )
    , ( 11, 0 )
    , ( 6, 2 )
    , ( 8, 2 )
    , ( 0, 3 )
    , ( 7, 3 )
    , ( 14, 3 )
    , ( 2, 6 )
    , ( 6, 6 )
    , ( 8, 6 )
    , ( 12, 6 )
    , ( 3, 7 )
    , ( 11, 7 )
    , ( 2, 8 )
    , ( 6, 8 )
    , ( 8, 8 )
    , ( 12, 8 )
    , ( 0, 11 )
    , ( 7, 11 )
    , ( 14, 11 )
    , ( 6, 12 )
    , ( 8, 12 )
    , ( 3, 14 )
    , ( 11, 14 )
    ]


{-| The game setup form. With `readonly` set, every input is disabled and the buttons are hidden;
this doubles as the settings view of an active game (see the gear button in `gameView`).
-}
setupView : Coord CssPixels -> Bool -> SetupModel -> Element SetupMsg
setupView windowSize isReadonly setup =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize

        padding =
            Ui.paddingXY
                (if isMobile then
                    8

                 else
                    16
                )
                0
    in
    Ui.column
        [ Ui.spacing
            (if isMobile then
                12

             else
                16
            )
        , Ui.paddingXY 0 16
        , Ui.background MyUi.tabBackground
        , Ui.height (Ui.px (tabBodyHeight windowSize OneOrGreater.seven))
        , Ui.heightMin 0
        , Ui.scrollable
        ]
        [ Ui.el [ Ui.Font.size 24, padding ] (Ui.text "Word Spelling Game settings")
        , Ui.column
            [ Ui.spacing
                (if isMobile then
                    12

                 else
                    16
                )
            , padding
            ]
            [ --setupSection
              --    (Ui.text "Time control")
              --    (Ui.row [ Ui.spacing 8, Ui.width Ui.shrink, Ui.contentBottom ]
              --        [ timeInput isReadonly "wsg_mainTimeInput" "Main time (minutes)" setup.mainTimeInput ChangedMainTimeInput
              --        , timeInput isReadonly "wsg_incrementInput" "Increment (seconds)" setup.incrementInput ChangedIncrementInput
              --        ]
              --    )
              if isReadonly then
                setupSection (Ui.text "Dictionary") (Ui.text (languageToString setup.language))

              else
                MyUi.radioColumn
                    (Dom.id "ws_language")
                    PressedLanguage
                    (Just setup.language)
                    "Dictionary"
                    (List.map (\language -> ( language, languageToString language )) allLanguages)
            , setupSection
                (Ui.row
                    []
                    [ Ui.text "Attempts per turn"
                    , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text " (# of tries you get place a valid word)")
                    ]
                )
                (Go.numberInput
                    { htmlId = "wsg_attemptsPerTurn"
                    , width = 60
                    , minValue = 1
                    , maxValue = 999
                    , value = OneOrGreater.toString setup.placeWordAttempts
                    , isReadonly = isReadonly
                    , onChange =
                        \value ->
                            OneOrGreater.fromString value
                                |> Maybe.withDefault OneOrGreater.one
                                |> ChangedPlaceWordAttempts
                    }
                )
            ]
        , MyUi.container
            setup.advancedSettingsExpanded
            (Dom.id "wsg_advancedSection")
            PressedExpandAdvancedSettings
            MyUi.background1
            isMobile
            "Advanced settings"
            [ setupSection
                (Ui.row
                    []
                    [ Ui.text "Bingo bonus"
                    , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text " (points for using a full tray)")
                    ]
                )
                (Go.numberInput
                    { htmlId = "wsg_fullTrayBonusInput"
                    , width = 60
                    , minValue = -999
                    , maxValue = 999
                    , value = String.fromInt setup.fullTrayBonus
                    , isReadonly = isReadonly
                    , onChange = ChangedFullTrayBonusInput
                    }
                )
            , setupSection
                (Ui.row
                    []
                    [ Ui.text "Tray size"
                    , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text " (how many letters you get)")
                    ]
                )
                (Go.numberInput
                    { htmlId = "wsg_traySizeInput"
                    , width = 60
                    , minValue = 1
                    , maxValue = 10
                    , value = String.fromInt setup.traySize
                    , isReadonly = isReadonly
                    , onChange = ChangedTraySizeInput
                    }
                )
            , setupSection
                (Ui.row
                    []
                    [ Ui.text "Letter distribution"
                    , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text " (spaces are wildcards)")
                    ]
                )
                (lettersInput isReadonly setup.letters)
            , case distributionInputLetters setup.letters of
                [] ->
                    Ui.none

                distributionChars ->
                    setupSection
                        (Ui.text "Letter values")
                        (Ui.row
                            [ Ui.spacing 8, Ui.wrap, Ui.width Ui.shrink ]
                            (List.map
                                (\char -> letterValueInput isReadonly char (letterValueInputFor char setup))
                                distributionChars
                            )
                        )
            , if isReadonly || (setup.letters == defaultLetters setup.language && SeqDict.isEmpty setup.letterValues) then
                Ui.none

              else
                MyUi.simpleButton (Dom.id "wsg_resetLetters") PressedResetLetters (Ui.text "Reset to default")
            ]
        , case setup.error of
            Just error ->
                Ui.el [ Ui.Font.color MyUi.dangerRed, padding ] (Ui.text error)

            Nothing ->
                Ui.none
        , if isReadonly then
            Ui.none

          else
            Go.startOrCancel "wsg" isMobile PressedCancel PressedStartGame
        ]


setupSection : Element SetupMsg -> Element SetupMsg -> Element SetupMsg
setupSection title content =
    Ui.column
        [ Ui.spacing 2, MyUi.prewrap ]
        [ Ui.el [ Ui.Font.weight 600 ] title
        , content
        ]


{-| The distinct letters in the distribution input, sorted, one value input each. Uses the same
reading of the string as `parseLetters` (space is a wildcard, other whitespace is ignored) but
doesn't care about case so the value inputs don't vanish while the user is fixing a case error.
-}
distributionInputLetters : String -> List Char
distributionInputLetters string =
    String.toList string
        |> List.filter (\char -> not (List.member char [ ' ', '\n', '\u{000D}', '\t' ]))
        |> List.map Char.toUpper
        |> List.Extra.unique
        |> List.sort


letterValueInput : Bool -> Char -> String -> Element SetupMsg
letterValueInput isReadonly char value =
    Ui.row
        [ Ui.spacing 4, Ui.width Ui.shrink ]
        [ Ui.el [ Ui.Font.bold, MyUi.monospace ] (Ui.text (String.fromChar char))
        , Go.numberInput
            { htmlId = "wsg_letterValue_" ++ String.fromChar char
            , width = 44
            , minValue = 0
            , maxValue = 999
            , value = value
            , isReadonly = isReadonly
            , onChange = ChangedLetterValue char
            }
        ]


lettersInput : Bool -> String -> Element SetupMsg
lettersInput isReadonly value =
    Html.textarea
        [ Html.Attributes.id "wsg_lettersInput"
        , Html.Attributes.value value
        , Html.Attributes.disabled isReadonly
        , Go.inputBackgroundColor isReadonly
        , Html.Attributes.style "font-size" "inherit"
        , Html.Attributes.style "color" "black"
        , Html.Attributes.style "font-family" "'DejaVu Sans Mono', monospace"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "100px"

        -- Wrap at any character (letter wrap) rather than only at spaces, since the distribution is
        -- essentially one long word.
        , Html.Attributes.style "word-break" "break-all"
        , Html.Attributes.style "padding" "8px"
        , Html.Attributes.style "box-sizing" "border-box"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Events.onInput ChangedLettersInput
        ]
        []
        |> Ui.html


defaultLetters : Language -> String
defaultLetters language =
    case language of
        English ->
            "  AAAAAAAAABBCCDDDDEEEEEEEEEEEEFFGGGHHIIIIIIIIIJKLLLLMMNNNNNNOOOOOOOOPPQRRRRRRSSSSTTTTTTUUUUVVWWXYYZ"

        Swedish ->
            "  AAAAAAAAABBCCDDDDDDDEEEEEEEEFFGGGGHHHIIIIIIJKKKLLLLLLLMMMNNNNNNNOOOOOPPPQRRRRRRRRRSSSSSSSSTTTTTTTUUUVVXYYZÅÅÄÄÖÖ"


{-| How many points a letter tile scores, as configured in the game setup.
-}
letterValue : ValidatedSetup -> Letter -> Int
letterValue setup letter =
    case NonemptyDict.get (Letter letter) setup.letters of
        Just data ->
            data.value

        Nothing ->
            0


defaultEnglishLetterValue : Char -> Int
defaultEnglishLetterValue char =
    case char of
        'A' ->
            1

        'B' ->
            3

        'C' ->
            3

        'D' ->
            2

        'E' ->
            1

        'F' ->
            4

        'G' ->
            2

        'H' ->
            4

        'I' ->
            1

        'J' ->
            8

        'K' ->
            5

        'L' ->
            1

        'M' ->
            3

        'N' ->
            1

        'O' ->
            1

        'P' ->
            3

        'Q' ->
            10

        'R' ->
            1

        'S' ->
            1

        'T' ->
            1

        'U' ->
            1

        'V' ->
            4

        'W' ->
            4

        'X' ->
            8

        'Y' ->
            4

        'Z' ->
            10

        _ ->
            1


defaultSwedishLetterValue : Char -> Int
defaultSwedishLetterValue char =
    case char of
        'A' ->
            1

        'B' ->
            4

        'C' ->
            8

        'D' ->
            1

        'E' ->
            1

        'F' ->
            4

        'G' ->
            2

        'H' ->
            3

        'I' ->
            1

        'J' ->
            8

        'K' ->
            3

        'L' ->
            1

        'M' ->
            3

        'N' ->
            1

        'O' ->
            2

        'P' ->
            3

        'Q' ->
            10

        'R' ->
            1

        'S' ->
            1

        'T' ->
            1

        'U' ->
            3

        'V' ->
            4

        'W' ->
            10

        'X' ->
            10

        'Y' ->
            8

        'Z' ->
            10

        'Å' ->
            4

        'Ä' ->
            4

        'Ö' ->
            4

        _ ->
            1


audio : Audio.Source -> Id UserId -> Shared -> GameData -> Audio
audio popSound currentUserId shared model =
    Audio.group
        [ case getPlayer currentUserId shared of
            Just _ ->
                Array.toList model.tiles
                    |> List.map
                        (\tile ->
                            Audio.group
                                [ Audio.audio popSound (Duration.addTo tile.createdAt tileFadeDelay)
                                , case tile.position of
                                    TileInTray _ _ ->
                                        Audio.silence

                                    TileOnBoard _ placedAt ->
                                        Audio.audio popSound placedAt
                                ]
                        )
                    |> Audio.group

            Nothing ->
                Audio.silence
        , case model.lastWordPlaced of
            Just { time, letterCount } ->
                List.range 0 (letterCount - 1)
                    |> List.map
                        (\index ->
                            Quantity.plus tileSlideDuration (Quantity.multiplyBy (toFloat index) tileSlideStagger)
                                |> Duration.addTo time
                                |> Audio.audio popSound
                        )
                    |> Audio.group

            Nothing ->
                Audio.silence
        ]


parseWordList : Result Http.Error String -> WordList
parseWordList result =
    case result of
        Ok text ->
            String.split "\n" text
                |> List.filterMap (\row -> String.split " " row |> List.head)
                |> Set.fromList
                |> WordList_Loaded

        Err error ->
            WordList_Error error


{-| The Free Dictionary API endpoint for an English word. Words are placed uppercase, so this
lowercases before building the URL. The response has no CORS restrictions, so the frontend can
call it directly (see `Frontend.handleGameOutMsgs`).
-}
definitionApiUrl : String -> String
definitionApiUrl word =
    "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ String.toLower word


{-| Decode the Free Dictionary API response into a flat list of part-of-speech groupings. The API
returns a list of entries, each with a `meanings` array; the meanings across every entry are
concatenated so callers get one list of `DictEntry`.
-}
decodeDefinition : Json.Decode.Decoder (List DictEntry)
decodeDefinition =
    Json.Decode.list
        (Json.Decode.field "meanings" (Json.Decode.list decodeDictEntry))
        |> Json.Decode.map List.concat


decodeDictEntry : Json.Decode.Decoder DictEntry
decodeDictEntry =
    Json.Decode.map2 DictEntry
        (Json.Decode.field "partOfSpeech" Json.Decode.string)
        (Json.Decode.field "definitions"
            (Json.Decode.list (Json.Decode.field "definition" Json.Decode.string))
        )


{-| Turn a dictionary API response into popup state. Any error (including the 404 the API returns
for a word it doesn't know), or a successful-but-empty response, becomes "not found".
-}
definitionResultToData : Result Http.Error (List DictEntry) -> WordDefinitionData
definitionResultToData result =
    case result of
        Ok (entry :: rest) ->
            WordDefinition_Loaded (entry :: rest)

        Ok [] ->
            WordDefinition_NotFound

        Err _ ->
            WordDefinition_NotFound
