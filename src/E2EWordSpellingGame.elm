module E2EWordSpellingGame exposing (tests)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Time as Time
import Game
import Id exposing (Id, UserId)
import Json.Encode
import Message
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import WordSpellingGame


tests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
tests normalConfig =
    T.testGroup
        "Word Spelling Game"
        [ E2EHelper.startTest
            "Word spelling game match"
            E2EHelper.startTime
            normalConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.tallDesktopWindow
                (\admin user ->
                    let
                        pointerEvent : ( Float, Float ) -> Json.Encode.Value
                        pointerEvent ( x, y ) =
                            Json.Encode.object
                                [ ( "timeStamp", Json.Encode.float 0 )
                                , ( "pointerId", Json.Encode.int 0 )
                                , ( "clientX", Json.Encode.float x )
                                , ( "clientY", Json.Encode.float y )
                                ]

                        pointerUpEvent : Json.Encode.Value
                        pointerUpEvent =
                            Json.Encode.object [ ( "timeStamp", Json.Encode.float 0 ) ]

                        dragTile delay tab from to =
                            T.group
                                [ tab.custom delay (Dom.id "elm-ui-root-id") "pointerdown" (pointerEvent from)
                                , tab.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerEvent to)
                                , tab.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerEvent to)
                                , tab.custom 100 (Dom.id "elm-ui-root-id") "pointerup" pointerUpEvent
                                ]

                        -- On a 1000px-wide desktop window the board sits at (258, 98) with 30px
                        -- cells (see WordSpellingGame.boardX / boardY / cellSize), and the tray
                        -- is directly below it.
                        trayTile : Float -> ( Float, Float )
                        trayTile index =
                            ( 283 + index * 54, toFloat (WordSpellingGame.boardY + 15 * 30) )

                        boardCell : Int -> Int -> ( Float, Float )
                        boardCell cx cy =
                            ( toFloat (273 + cx * 30), toFloat (WordSpellingGame.boardY + cy * 30) )
                    in
                    [ -- Admin creates a Word Spelling Game match in the DM with the other user.
                      admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.Game_WordSpellingGame))
                    , admin.input 100 (Dom.id "wsg_lettersInput") "aadeeiilmnnoorrsstt"
                    , admin.click 100 (Dom.id "wsg_start")

                    -- The other user opens the same match and joins it.
                    , user.click 2000 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.click 100 (Dom.id "wordSpellingGame_joinGame")
                    , -- Admin's fresh tray is "A O A L D O M" in slots 0..6, so LOAD is slots 3,1,0,4.
                      -- It covers the centre square (7,7) and scores double for the whole word: 10.
                      T.collapsableGroup
                        "Place \"load\""
                        [ dragTile 100 admin (trayTile 3) (boardCell 6 7)
                        , dragTile 100 admin (trayTile 1) (boardCell 7 7)
                        , dragTile 100 admin (trayTile 0) (boardCell 8 7)
                        , dragTile 100 admin (trayTile 4) (boardCell 9 7)
                        , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_6_7")
                        , admin.snapshotView 5000 { name = "Place \"load\"" }
                        , user.snapshotView 0 { name = "Place \"load\"" }
                        ]
                    , -- User's fresh tray is "N E N E S I T" in slots 0..6. Placing N, S, E around the
                      -- committed O at (7,7) spells NOSE down column 7, and empties the letter bag.
                      T.collapsableGroup
                        "Place \"nose\""
                        [ dragTile 100 user (trayTile 0) (boardCell 7 6)
                        , dragTile 100 user (trayTile 4) (boardCell 7 8)
                        , dragTile 100 user (trayTile 1) (boardCell 7 9)
                        , user.click 100 (Dom.id "wordSpellingGame_submitLine_v_7_6")
                        , admin.snapshotView 5000 { name = "Place \"nose\"" }
                        , user.snapshotView 0 { name = "Place \"nose\"" }
                        ]
                    , T.collapsableGroup
                        "Drop a tray tile one slot to the right"
                        -- Regression test for a tray-drop off-by-one: the dragged tile is drawn centred
                        -- on the cursor, so dropping the first tile centred just right of the next slot
                        -- must land it in that next slot, not skip a whole slot past it. (This happens on
                        -- the user's turn once every word is placed, so it doesn't affect the scores.)
                        [ dragTile 100 user (trayTile 0) (trayTile 1.1)
                        , user.snapshotView 500 { name = "Drop tray tile one slot to the right" }
                        ]
                    , -- The bag is empty, so both players pass in turn (admin first) to end the game.
                      admin.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                    , user.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                    , admin.checkView
                        100
                        -- The leaderboard renders each player's name and score suffix as separate
                        -- elements (see WordSpellingGame.playerRow), so they're matched separately.
                        (Test.Html.Query.has
                            [ Test.Html.Selector.exactText "AT"
                            , Test.Html.Selector.exactText ": 10 (winner)"
                            , Test.Html.Selector.exactText "Stevie Steve"
                            , Test.Html.Selector.exactText ": 4"
                            ]
                        )
                    , user.checkView
                        100
                        -- The leaderboard renders each player's name and score suffix as separate
                        -- elements (see WordSpellingGame.playerRow), so they're matched separately.
                        (Test.Html.Query.has
                            [ Test.Html.Selector.exactText "AT"
                            , Test.Html.Selector.exactText ": 10 (winner)"
                            , Test.Html.Selector.exactText "Stevie Steve"
                            , Test.Html.Selector.exactText ": 4"
                            ]
                        )
                    , admin.snapshotView 0 { name = "Game ended" }
                    ]
                )
            ]
        , E2EHelper.startTest
            "Word spelling game match (mobile)"
            E2EHelper.startTime
            normalConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.mobileWindow
                (\admin user ->
                    let
                        windowSize : Coord CssPixels
                        windowSize =
                            Coord.xy E2EHelper.mobileWindow.width E2EHelper.mobileWindow.height

                        -- Rebuild the same validated setup the game creates so we can compute exact
                        -- board/tray touch coordinates (only its tray size and the window matter here).
                        setup : WordSpellingGame.ValidatedSetup
                        setup =
                            case
                                WordSpellingGame.updateSetup
                                    (Time.millisToPosix 0)
                                    (Id.fromInt 0)
                                    WordSpellingGame.PressedStartGame
                                    { initSetup | letters = "aadeeiilmnnoorrsstt" }
                                    |> Tuple.second
                                    |> List.filterMap
                                        (\outMsg ->
                                            case outMsg of
                                                WordSpellingGame.OutLocalChange (WordSpellingGame.StartMatch _ validated) ->
                                                    Just validated

                                                _ ->
                                                    Nothing
                                        )
                                    |> List.head
                            of
                                Just validated ->
                                    validated

                                Nothing ->
                                    Debug.todo "the fixed letters always validate"

                        -- One touch, reported the way the mobile frontend decodes touch events.
                        touchEvent : Float -> ( Float, Float ) -> Json.Encode.Value
                        touchEvent timeStamp ( x, y ) =
                            Json.Encode.object
                                [ ( "timeStamp", Json.Encode.float timeStamp )
                                , ( "touches"
                                  , Json.Encode.object
                                        [ ( "length", Json.Encode.int 1 )
                                        , ( "0"
                                          , Json.Encode.object
                                                [ ( "identifier", Json.Encode.int 0 )
                                                , ( "clientX", Json.Encode.float x )
                                                , ( "clientY", Json.Encode.float y )
                                                , ( "target", Json.Encode.object [ ( "id", Json.Encode.string "elm-ui-root-id" ) ] )
                                                ]
                                          )
                                        ]
                                  )
                                ]

                        touchEndEvent : Float -> Json.Encode.Value
                        touchEndEvent timeStamp =
                            Json.Encode.object [ ( "timeStamp", Json.Encode.float timeStamp ) ]

                        -- Drag a tile from one screen position to another. The timeStamp is spaced far
                        -- enough from the previous drag that the board's zoom animation has settled by
                        -- the time the tile is dropped, matching boardTouchCoord's settled zoom.
                        dragTile timeStamp tab from to =
                            T.group
                                [ tab.custom 100 (Dom.id "elm-ui-root-id") "touchstart" (touchEvent timeStamp from)
                                , tab.custom 100 (Dom.id "elm-ui-root-id") "touchmove" (touchEvent timeStamp to)
                                , tab.custom 100 (Dom.id "elm-ui-root-id") "touchmove" (touchEvent timeStamp to)
                                , tab.custom 100 (Dom.id "elm-ui-root-id") "touchend" (touchEndEvent timeStamp)
                                ]

                        trayXY : Int -> ( Float, Float )
                        trayXY slot =
                            floatCoord (WordSpellingGame.trayTouchCoord setup windowSize slot)

                        -- The screen position for board cell `cell`, given the tiles the current player
                        -- has already placed this turn (what the mobile zoom centres on).
                        boardXY : List ( Int, Int ) -> ( Int, Int ) -> ( Float, Float )
                        boardXY placed cell =
                            floatCoord (WordSpellingGame.boardTouchCoord setup windowSize placed cell)
                    in
                    [ -- Both players open the DM and the match. On mobile the "open DM" buttons live
                      -- behind the show-members button in the channel header.
                      admin.click 0 (Dom.id "guild_showMembers")
                    , admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.Game_WordSpellingGame))
                    , admin.input 100 (Dom.id "wsg_lettersInput") "aadeeiilmnnoorrsstt"
                    , admin.click 100 (Dom.id "wsg_start")
                    , user.click 2000 (Dom.id "guild_showMembers")
                    , user.click 100 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.click 100 (Dom.id "wordSpellingGame_joinGame")
                    , -- Admin's fresh tray is "A O A L D O M" (slots 3,1,0,4 = L,O,A,D). LOAD covers the
                      -- centre and scores 10. After the first tile the board zooms, so tiles 2..4 use
                      -- boardXY with the already-placed cells.
                      T.collapsableGroup
                        "Place \"load\""
                        [ dragTile 1000 admin (trayXY 3) (boardXY [] ( 6, 7 ))
                        , admin.snapshotView 100 { name = "Place \"l\"" }
                        , dragTile 2000 admin (trayXY 1) (boardXY [ ( 6, 7 ) ] ( 7, 7 ))
                        , admin.snapshotView 100 { name = "Place \"o\"" }
                        , dragTile 3000 admin (trayXY 0) (boardXY [ ( 6, 7 ), ( 7, 7 ) ] ( 8, 7 ))
                        , dragTile 4000 admin (trayXY 4) (boardXY [ ( 6, 7 ), ( 7, 7 ), ( 8, 7 ) ] ( 9, 7 ))
                        , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_6_7")
                        , admin.snapshotView 5000 { name = "Place \"load\"" }
                        ]
                    , -- User's fresh tray is "N E N E S I T" (slots 0,4,1 = N,S,E). NOSE runs down column
                      -- 7 through the committed O, scores 4, and empties the bag.
                      T.collapsableGroup
                        "Place \"nose\""
                        [ dragTile 1000 user (trayXY 0) (boardXY [] ( 7, 6 ))
                        , dragTile 2000 user (trayXY 4) (boardXY [ ( 7, 6 ) ] ( 7, 8 ))
                        , dragTile 3000 user (trayXY 1) (boardXY [ ( 7, 6 ), ( 7, 8 ) ] ( 7, 9 ))
                        , user.click 100 (Dom.id "wordSpellingGame_submitLine_v_7_6")
                        , user.snapshotView 5000 { name = "Place \"nose\"" }
                        ]
                    , -- The bag is empty, so both players pass (admin first) to end the game.
                      admin.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                    , user.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                    , -- On mobile the leaderboard only lists the winner (see WordSpellingGame.leaderboardView).
                      admin.checkView
                        100
                        (Test.Html.Query.has
                            [ Test.Html.Selector.exactText "AT"
                            , Test.Html.Selector.exactText ": 10 (winner)"
                            ]
                        )
                    , user.checkView
                        100
                        (Test.Html.Query.has
                            [ Test.Html.Selector.exactText "AT"
                            , Test.Html.Selector.exactText ": 10 (winner)"
                            ]
                        )
                    , admin.snapshotView 0 { name = "Game ended" }
                    ]
                )
            ]
        ]


initSetup : WordSpellingGame.SetupModel
initSetup =
    WordSpellingGame.initSetup


floatCoord : Coord CssPixels -> ( Float, Float )
floatCoord coord =
    ( toFloat (Coord.xRaw coord), toFloat (Coord.yRaw coord) )
