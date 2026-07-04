module E2EWordSpellingGame exposing (tests)

import Audio
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Time as Time
import FrontendExtra
import Game
import Json.Encode
import Message
import OneOrGreater
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
                    [ -- The headless test never loads /pop.mp3, so tell each client's audio system the
                      -- load succeeded (requestId 0 is the pop sound, the only sound the app loads). Once
                      -- popSound is Ok, FrontendExtra.audio actually schedules the pops we assert on below.
                      admin.portEvent 0 "audioPortFromJs" popLoadedEvent
                    , user.portEvent 0 "audioPortFromJs" popLoadedEvent

                    -- Admin creates a Word Spelling Game match in the DM with the other user.
                    , admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.input 100 (Dom.id "wsg_lettersInput") "aadeeiilmnnoorrsstt"
                    , admin.click 100 (Dom.id "wsg_start")
                    , T.collapsableGroup
                        "Clear placed tiles"
                        [ -- Admin drags one tile onto the board: 7 fade-in pops for the held tiles plus
                          -- 1 placement pop for the tile now resting on the board.
                          dragTile 100 admin (trayTile 3) (boardCell 6 7)
                        , admin.checkModel 100 (checkPopCount 8)
                        , -- The clear button only appears while the player has tiles on the board.
                          -- Clicking it returns every placed tile to the tray, so the placement pop is
                          -- gone and only the 7 fade-in pops remain.
                          admin.click 100 (Dom.id "wordSpellingGame_clearBoard")
                        , admin.checkModel 100 (checkPopCount 7)
                        ]
                    , -- Admin's fresh tray is "A O A L D O M" in slots 0..6, so LOAD is slots 3,1,0,4.
                      -- It covers the centre square (7,7) and scores double for the whole word: 10.
                      T.collapsableGroup
                        "Place \"load\""
                        [ dragTile 100 admin (trayTile 3) (boardCell 6 7)
                        , dragTile 100 admin (trayTile 1) (boardCell 7 7)
                        , dragTile 100 admin (trayTile 0) (boardCell 8 7)
                        , dragTile 100 admin (trayTile 4) (boardCell 9 7)
                        , -- Admin is holding all 7 tray tiles (each schedules a fade-in pop) with 4 of
                          -- them placed on the board (each schedules a placement pop): 7 + 4 = 11 pops.
                          admin.checkModel 100 (checkPopCount 11)
                        , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_6_7")
                        , -- After committing LOAD, admin's board is clear and the tray is refilled back to
                          -- 7 tiles, so only the 7 fade-in pops remain (a mover doesn't animate its own word).
                          admin.checkModel 100 (checkPopCount 7)
                        , admin.snapshotView 5000 { name = "Place \"load\"" }
                        , user.snapshotView 0 { name = "Place \"load\"" }
                        ]

                    -- The other user opens the same match and joins it.
                    , user.click 2000 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.click 100 (Dom.id "wordSpellingGame_joinGame")
                    , T.collapsableGroup
                        "Place \"rot\""
                        [ user.checkModel 100 (checkPopCount 7)
                        , dragTile 100 user (trayTile 4) (boardCell 7 6)
                        , dragTile 100 user (trayTile 3) (boardCell 7 8)
                        , user.click 100 (Dom.id "wordSpellingGame_submitLine_v_7_6")
                        , admin.snapshotView 5000 { name = "Place \"rot\"" }
                        , user.snapshotView 0 { name = "Place \"rot\"" }
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
                            , Test.Html.Selector.exactText ": 3"
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
                            , Test.Html.Selector.exactText ": 3"
                            ]
                        )
                    , admin.snapshotView 0 { name = "Game ended" }
                    ]
                )
            ]
        , E2EHelper.startTest
            "Check user can't join after first round"
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
                    [ -- The headless test never loads /pop.mp3, so tell each client's audio system the
                      -- load succeeded (requestId 0 is the pop sound, the only sound the app loads). Once
                      -- popSound is Ok, FrontendExtra.audio actually schedules the pops we assert on below.
                      admin.portEvent 0 "audioPortFromJs" popLoadedEvent
                    , user.portEvent 0 "audioPortFromJs" popLoadedEvent

                    -- Admin creates a Word Spelling Game match in the DM with the other user.
                    , admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.input 100 (Dom.id "wsg_lettersInput") "aadeeiilmnnoorrsstt"
                    , admin.click 100 (Dom.id "wsg_start")

                    -- The other user opens the same match and joins it.
                    , user.click 2000 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "wordSpellingGame_joinGame" ])
                    , admin.click 100 (Dom.id "wordSpellingGame_replaceTray")
                    , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "wordSpellingGame_joinGame" ])
                    , T.collapsableGroup
                        "Place \"load\""
                        [ dragTile 100 admin (trayTile 3) (boardCell 6 7)
                        , dragTile 100 admin (trayTile 1) (boardCell 7 7)
                        , dragTile 100 admin (trayTile 0) (boardCell 8 7)
                        , dragTile 100 admin (trayTile 4) (boardCell 9 7)
                        , -- Admin is holding all 7 tray tiles (each schedules a fade-in pop) with 4 of
                          -- them placed on the board (each schedules a placement pop): 7 + 4 = 11 pops.
                          admin.checkModel 100 (checkPopCount 11)
                        , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_6_7")
                        , -- After committing LOAD, admin's board is clear and the tray is refilled back to
                          -- 7 tiles, so only the 7 fade-in pops remain (a mover doesn't animate its own word).
                          admin.checkModel 100 (checkPopCount 7)
                        , admin.snapshotView 5000 { name = "Place \"load\"" }
                        , user.snapshotView 0 { name = "Place \"load\"" }
                        ]
                    , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wordSpellingGame_joinGame" ])
                    ]
                )
            ]
        , E2EHelper.startTest
            "Game ends when a player runs out of letters"
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
                        -- is directly below it. Tray tiles cap at 50px however small the tray, so
                        -- these positions match the other desktop tests despite the 2-tile tray.
                        trayTile : Float -> ( Float, Float )
                        trayTile index =
                            ( 283 + index * 54, toFloat (WordSpellingGame.boardY + 15 * 30) )

                        boardCell : Int -> Int -> ( Float, Float )
                        boardCell cx cy =
                            ( toFloat (273 + cx * 30), toFloat (WordSpellingGame.boardY + cy * 30) )
                    in
                    [ -- Admin creates a match with a 2-tile tray and a bag of exactly four A tiles:
                      -- admin draws two, the joining user draws the other two, and the bag is empty.
                      -- (The bingo bonus is zeroed so the final score stays easy to read.)
                      admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.Game_WordSpellingGame))
                    , admin.input 100 (Dom.id "wsg_traySizeInput") "2"
                    , admin.input 100 (Dom.id "wsg_fullTrayBonusInput") "0"
                    , admin.input 100 (Dom.id "wsg_lettersInput") "aaaa"
                    , admin.click 100 (Dom.id "wsg_start")

                    -- The other user opens the same match and joins before the first move,
                    -- emptying the bag.
                    , user.click 2000 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.click 100 (Dom.id "wordSpellingGame_joinGame")

                    -- Admin plays both tiles as "AA" through the centre square: (1+1)*2 = 4. Their
                    -- tray is now empty with nothing left in the bag, so the game must end right
                    -- away — the other user still holds two tiles and nobody has passed.
                    , T.collapsableGroup
                        "Place \"aa\""
                        [ dragTile 100 admin (trayTile 0) (boardCell 7 7)
                        , dragTile 100 admin (trayTile 1) (boardCell 8 7)
                        , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_7_7")
                        ]
                    , admin.checkView
                        100
                        -- The leaderboard renders each player's name and score suffix as separate
                        -- elements (see WordSpellingGame.playerRow), so they're matched separately.
                        (Test.Html.Query.has
                            [ Test.Html.Selector.exactText "Game over"
                            , Test.Html.Selector.exactText "AT"
                            , Test.Html.Selector.exactText ": 4 (winner)"
                            , Test.Html.Selector.exactText "Stevie Steve"
                            , Test.Html.Selector.exactText ": 0"
                            ]
                        )
                    , user.checkView
                        100
                        (Test.Html.Query.has
                            [ Test.Html.Selector.exactText "Game over"
                            , Test.Html.Selector.exactText "AT"
                            , Test.Html.Selector.exactText ": 4 (winner)"
                            , Test.Html.Selector.exactText "Stevie Steve"
                            , Test.Html.Selector.exactText ": 0"
                            ]
                        )
                    , admin.snapshotView 0 { name = "Game ended out of letters" }
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

                        -- A representative phone-notch safe-area inset, in pixels.
                        safeAreaInsetTop : Int
                        safeAreaInsetTop =
                            47

                        -- One touch, reported the way the mobile frontend decodes touch events. The
                        -- board coordinates the drags aim at are in the layout space below the safe-area
                        -- inset, but a real device reports touches from the viewport top, so the inset is
                        -- added back into clientY here. The frontend must subtract it again to hit the
                        -- right cell (regression test for safe-area-inset drag handling).
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
                                                , ( "clientY", Json.Encode.float (y + toFloat safeAreaInsetTop) )
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
                            floatCoord (WordSpellingGame.trayTouchCoord OneOrGreater.seven windowSize slot)

                        -- The screen position for board cell `cell`, given the tiles the current player
                        -- has already placed this turn (what the mobile zoom centres on).
                        boardXY : List ( Int, Int ) -> ( Int, Int ) -> ( Float, Float )
                        boardXY placed cell =
                            floatCoord (WordSpellingGame.boardTouchCoord OneOrGreater.seven windowSize placed cell)
                    in
                    [ -- Pretend both players are on a phone with a notch: their touch coordinates come
                      -- in offset by the safe-area inset (see touchEvent), and the frontend has to undo
                      -- that offset when hit-testing the board.
                      admin.portEvent 100 "load_startup_data_from_js" (E2EHelper.startupDataJsonWithInset E2EHelper.firefoxDesktop safeAreaInsetTop)
                    , user.portEvent 100 "load_startup_data_from_js" (E2EHelper.startupDataJsonWithInset E2EHelper.firefoxDesktop safeAreaInsetTop)

                    -- Both players open the DM and the match. On mobile the "open DM" buttons live
                    -- behind the show-members button in the channel header.
                    , admin.click 0 (Dom.id "guild_showMembers")
                    , admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
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


{-| The message the audio port's JS side sends back after successfully loading a sound (see
Audio.decodeFromJSMsg: type 1 is a load success). The app only ever loads one sound, the pop
sound, at requestId 0.
-}
popLoadedEvent : Json.Encode.Value
popLoadedEvent =
    Json.Encode.object
        [ ( "type", Json.Encode.int 1 )
        , ( "requestId", Json.Encode.int 0 )
        , ( "bufferId", Json.Encode.int 0 )
        , ( "durationInSeconds", Json.Encode.float 1 )
        ]


floatCoord : Coord CssPixels -> ( Float, Float )
floatCoord coord =
    ( toFloat (Coord.xRaw coord), toFloat (Coord.yRaw coord) )


{-| Every pop the game wants to play is a `Audio.audio popSound _` leaf in the tree
`FrontendExtra.audio` builds. Walk that tree and collect the start time of each leaf, so a
test can assert the pop sound fires at exactly the places the game means it to.
-}
popStartTimes : FrontendModel -> List Time.Posix
popStartTimes model =
    FrontendExtra.audio (Audio.audioData model) (Audio.userModel model)
        |> collectPopStartTimes


collectPopStartTimes : Audio.Audio -> List Time.Posix
collectPopStartTimes node =
    case node of
        Audio.Group group ->
            List.concatMap collectPopStartTimes group

        Audio.BasicAudio { startTime } ->
            [ startTime ]

        Audio.Effect effect ->
            collectPopStartTimes effect.audio


{-| Assert the number of pops `FrontendExtra.audio` is currently scheduling for a client.
The pop count is diagnostic: the game schedules one fade-in pop per tile the player holds
(tray or board), one extra pop for each tile placed on the board this turn, and one pop per
letter of the opponent's most recently placed word (its slide-in animation).
-}
checkPopCount : Int -> FrontendModel -> Result String ()
checkPopCount expected model =
    let
        actual : Int
        actual =
            List.length (popStartTimes model)
    in
    if actual == expected then
        Ok ()

    else
        Err ("Expected " ++ String.fromInt expected ++ " pop sounds but found " ++ String.fromInt actual)
