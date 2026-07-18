module E2EWordSpellingGame exposing (tests)

import Audio
import Broadcast
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import DmChannelId
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Time as Time
import FrontendExtra
import Game
import Id exposing (ChannelMessageId, Id)
import IdArray
import Json.Encode
import List.Nonempty
import Message
import OneOrGreater
import Route exposing (ShowMembersTab(..))
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import UserSession
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

                    -- Cancel from the setup screen returns to the game select view.
                    , admin.click 100 (Dom.id "wsg_cancel")
                    , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_start" ])
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.click 100 (Dom.id "wsg_advancedSection")
                    , admin.input 100 (Dom.id "wsg_lettersInput") "AADEEIILMNNOORRSSTT"
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
                    , T.collapsableGroup
                        "Game settings gear toggles the read-only settings view"
                        [ -- The board is showing, so the setup's letter distribution input isn't present.
                          admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_lettersInput" ])
                        , admin.click 100 (Dom.id "wsg_settings")

                        -- Now the read-only settings show the distribution, but no start/cancel buttons.
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "wsg_lettersInput" ])
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_start" ])
                        , admin.snapshotView 100 { name = "Word spelling game settings" }

                        -- Clicking the gear again returns to the board.
                        , admin.click 100 (Dom.id "wsg_settings")
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_lettersInput" ])
                        ]

                    -- The other user opens the same match and joins it.
                    , user.click 2000 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.click 100 (Dom.id "wordSpellingGame_joinGame")
                    , T.collapsableGroup
                        "Place \"rot\""
                        [ user.checkModel 100 (checkPopCount 11)
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
        , wordSpellingGamePremove normalConfig
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
                    , admin.click 100 (Dom.id "wsg_advancedSection")
                    , admin.input 100 (Dom.id "wsg_lettersInput") "AADEEIILMNNOORRSSTT"
                    , admin.click 100 (Dom.id "wsg_start")

                    -- The other user opens the same match and joins it.
                    , user.click 2000 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "wordSpellingGame_joinGame" ])
                    , admin.click 100 (Dom.id "wordSpellingGame_replaceTray")
                    , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "wordSpellingGame_joinGame" ])
                    , T.collapsableGroup
                        "Place \"date\""
                        [ dragTile 4000 admin (trayTile 3) (boardCell 6 7)
                        , dragTile 100 admin (trayTile 6) (boardCell 7 7)
                        , dragTile 100 admin (trayTile 5) (boardCell 8 7)
                        , dragTile 100 admin (trayTile 2) (boardCell 9 7)
                        , admin.checkModel 100 (checkPopCount 11)
                        , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_6_7")
                        , admin.checkModel 100 (checkPopCount 7)
                        , admin.snapshotView 5000 { name = "Place \"date\"" }
                        , user.snapshotView 0 { name = "Place \"date\"" }
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
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.click 100 (Dom.id "wsg_advancedSection")
                    , admin.input 100 (Dom.id "wsg_traySizeInput") "2"
                    , admin.input 100 (Dom.id "wsg_fullTrayBonusInput") "0"
                    , admin.input 100 (Dom.id "wsg_lettersInput") "AAAA"
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
                    , -- Both players were viewing the game when it ended, so neither may get a
                      -- game-over push notification.
                      E2EHelper.checkNoNotification "AT played AA (+4). The game has ended. AT won with 4 points!"
                    , admin.snapshotView 0 { name = "Game ended out of letters" }
                    , T.connectFrontend
                        100
                        E2EHelper.sessionId0
                        (Route.encode
                            (Route.DmRoute
                                { channelId = DmChannelId.fromUserIds (Id.fromInt 2) Broadcast.adminUserId
                                , threadRoute = Route.NoThreadWithFriends Nothing HideMembersTab
                                , tab = Just (UserSession.ChannelHeaderTab_Games (Just (Id.fromInt 0)))
                                }
                            )
                        )
                        E2EHelper.iphone14Window
                        (\userReload ->
                            [ T.andThen
                                10
                                (\data -> [ userReload.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.safariIphone) ])
                            , userReload.snapshotView 100 { name = "Game ended out of letters, mobile" }
                            ]
                        )
                    ]
                )
            ]
        , E2EHelper.startTest
            "Running out of place-word attempts passes the turn and resets the count"
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

                        -- Same board/tray geometry as the other tall-desktop tests. Tray tiles cap
                        -- at 50px however small the tray, so these positions match despite the
                        -- 2-tile tray.
                        trayTile : Float -> ( Float, Float )
                        trayTile index =
                            ( 283 + index * 54, toFloat (WordSpellingGame.boardY + 15 * 30) )

                        boardCell : Int -> Int -> ( Float, Float )
                        boardCell cx cy =
                            ( toFloat (273 + cx * 30), toFloat (WordSpellingGame.boardY + cy * 30) )

                        -- Placing both Q tiles horizontally through the centre square is always a
                        -- legal placement but "QQ" is never a real word, so every submission is
                        -- rejected and burns one place-word attempt.
                        placeInvalidQQ delay tab =
                            T.group
                                [ dragTile delay tab (trayTile 0) (boardCell 7 7)
                                , dragTile 100 tab (trayTile 1) (boardCell 8 7)
                                , tab.click 100 (Dom.id "wordSpellingGame_submitLine_h_7_7")
                                ]
                    in
                    [ -- Admin creates a match whose bag is all Q tiles (so the only word the players
                      -- can spell, "QQ", is a legal placement but never valid) and gives each turn
                      -- two attempts to place a valid word.
                      admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.click 100 (Dom.id "wsg_advancedSection")
                    , admin.input 100 (Dom.id "wsg_traySizeInput") "2"
                    , admin.input 100 (Dom.id "wsg_fullTrayBonusInput") "0"
                    , admin.input 100 (Dom.id "wsg_lettersInput") "QQQQQQQQ"
                    , admin.input 100 (Dom.id "wsg_attemptsPerTurn") "2"
                    , admin.click 100 (Dom.id "wsg_start")

                    -- The other user opens the same match and joins, so turns alternate between the
                    -- two players.
                    , user.click 2000 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.click 100 (Dom.id "wordSpellingGame_joinGame")

                    -- It starts on the admin's turn with both attempts available.
                    , T.checkState 1000 (\state -> checkWordSpellingState { turnCount = 0, attemptsLeft = 2 } state.backend)

                    -- The admin's first rejected word uses one attempt but keeps their turn.
                    , T.collapsableGroup
                        "Admin's first failed attempt"
                        [ placeInvalidQQ 100 admin
                        , T.checkState 2000 (\state -> checkWordSpellingState { turnCount = 0, attemptsLeft = 1 } state.backend)
                        ]

                    -- The second rejected word uses the last attempt, so the turn passes to the
                    -- other player and the attempts reset back to two.
                    , T.collapsableGroup
                        "Admin runs out of attempts"
                        [ placeInvalidQQ 2000 admin
                        , T.checkState 2000 (\state -> checkWordSpellingState { turnCount = 1, attemptsLeft = 2 } state.backend)
                        ]

                    -- The attempts always reset when a turn ends, even when the turn ends before
                    -- running out: the user fails once (2 -> 1) then swaps their tray to end the
                    -- turn, and the admin's next turn starts back at two attempts.
                    , T.collapsableGroup
                        "Attempts reset when a turn ends early"
                        [ placeInvalidQQ 100 user
                        , T.checkState 2000 (\state -> checkWordSpellingState { turnCount = 1, attemptsLeft = 1 } state.backend)
                        , user.click 100 (Dom.id "wordSpellingGame_replaceTray")
                        , T.checkState 2000 (\state -> checkWordSpellingState { turnCount = 2, attemptsLeft = 2 } state.backend)
                        , admin.snapshotView 0 { name = "After a few failed moves" }
                        ]
                    ]
                )
            ]
        , E2EHelper.startTest
            "Word spelling game match (mobile)"
            E2EHelper.startTime
            normalConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.iphone14Window
                (\admin user ->
                    let
                        windowSize : Coord CssPixels
                        windowSize =
                            Coord.xy E2EHelper.iphone14Window.width E2EHelper.iphone14Window.height

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
                      T.andThen
                        10
                        (\data -> [ admin.portEvent 100 "load_startup_data_from_js" (E2EHelper.startupDataJsonWithInset data.time E2EHelper.firefoxDesktop safeAreaInsetTop False) ])
                    , T.andThen
                        10
                        (\data -> [ user.portEvent 100 "load_startup_data_from_js" (E2EHelper.startupDataJsonWithInset data.time E2EHelper.firefoxDesktop safeAreaInsetTop False) ])

                    -- Both players open the DM and the match. On mobile the "open DM" buttons live
                    -- behind the show-members button in the channel header.
                    , admin.click 0 (Dom.id "guild_showMembers")
                    , admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.click 100 (Dom.id "wsg_advancedSection")
                    , admin.input 100 (Dom.id "wsg_lettersInput") "AADEEIILMNNOORRSSTT"
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
        , E2EHelper.startTest
            "Word spelling game in a guild channel"
            E2EHelper.startTime
            normalConfig
            [ E2EHelper.connectFourUsersAndJoinNewGuild
                E2EHelper.tallDesktopWindow
                (\admin userA userB watcher ->
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

                        -- Same board geometry as the desktop DM test above: the games tab is laid
                        -- out identically in guild channels.
                        trayTile : Float -> ( Float, Float )
                        trayTile index =
                            ( 283 + index * 54, toFloat (WordSpellingGame.boardY + 15 * 30) )

                        boardCell : Int -> Int -> ( Float, Float )
                        boardCell cx cy =
                            ( toFloat (273 + cx * 30), toFloat (WordSpellingGame.boardY + cy * 30) )
                    in
                    [ -- Everyone starts out viewing the guild's first channel. The admin creates a
                      -- match whose bag contains only "a" tiles, so every tray is predictable no
                      -- matter the draw order (and AA is a valid word). A is bumped from its
                      -- default 1 point to 2 via the per-letter value input.
                      admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.click 100 (Dom.id "wsg_advancedSection")
                    , admin.input 100 (Dom.id "wsg_lettersInput") (String.repeat 40 "A")
                    , admin.input 100 (Dom.id "wsg_letterValue_A") "2"
                    , admin.click 100 (Dom.id "wsg_start")
                    , T.checkState
                        100
                        (\state ->
                            case guildChannelGames state.backend of
                                [ ( _, Game.GameData_WordSpellingGame _ _ shared ) ] ->
                                    if List.Nonempty.length shared.players == 1 then
                                        Ok ()

                                    else
                                        Err "Expected only the match creator to have joined"

                                _ ->
                                    Err "Expected one word spelling game in the guild channel"
                        )
                    , T.andThen
                        100
                        (\state ->
                            case guildChannelGames state.backend of
                                [ ( matchId, _ ) ] ->
                                    [ -- The second and third members open the match from its message
                                      -- card and join it. The fourth member only watches.
                                      userA.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString matchId))
                                    , userA.click 100 (Dom.id "wordSpellingGame_joinGame")
                                    , userB.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString matchId))
                                    , userB.click 100 (Dom.id "wordSpellingGame_joinGame")
                                    , watcher.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString matchId))
                                    , T.checkState
                                        100
                                        (\state2 ->
                                            case guildChannelGames state2.backend of
                                                [ ( _, Game.GameData_WordSpellingGame _ _ shared ) ] ->
                                                    if List.Nonempty.length shared.players == 3 then
                                                        Ok ()

                                                    else
                                                        Err "Expected three players to have joined the match"

                                                _ ->
                                                    Err "Expected one word spelling game in the guild channel"
                                        )

                                    -- One move per player, in join order. Every tile is an "a", so
                                    -- each move spells AA. The words staircase down-right, each new
                                    -- domino touching the previous one at a corner, so every main
                                    -- and cross word is exactly AA and no invalid AAA run appears.
                                    , T.collapsableGroup
                                        "Admin places AA across the centre"
                                        [ dragTile 100 admin (trayTile 0) (boardCell 7 7)
                                        , dragTile 100 admin (trayTile 1) (boardCell 8 7)
                                        , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_7_7")
                                        ]
                                    , T.collapsableGroup
                                        "Second player places AA one step down-right"
                                        [ dragTile 100 userA (trayTile 0) (boardCell 8 8)
                                        , dragTile 100 userA (trayTile 1) (boardCell 9 8)
                                        , userA.click 100 (Dom.id "wordSpellingGame_submitLine_h_8_8")
                                        ]
                                    , T.collapsableGroup
                                        "Third player places AA another step down-right"
                                        [ dragTile 100 userB (trayTile 0) (boardCell 9 9)
                                        , dragTile 100 userB (trayTile 1) (boardCell 10 9)
                                        , userB.click 100 (Dom.id "wordSpellingGame_submitLine_h_9_9")
                                        ]
                                    , T.checkState
                                        100
                                        (\state2 ->
                                            case guildChannelGames state2.backend of
                                                [ ( _, Game.GameData_WordSpellingGame _ _ shared ) ] ->
                                                    if SeqDict.size shared.board /= 6 then
                                                        Err
                                                            ("Expected 6 tiles on the board but got "
                                                                ++ String.fromInt (SeqDict.size shared.board)
                                                            )

                                                    else if shared.turnCount /= 3 then
                                                        Err "Expected it to be the creator's turn again after three moves"

                                                    else
                                                        Ok ()

                                                _ ->
                                                    Err "Expected one word spelling game in the guild channel"
                                        )

                                    -- The watcher (who never joined) sees all three players and the
                                    -- moves as they happen. The admin's opening AA scores the custom
                                    -- letter value: (2+2) doubled by the centre square = 8.
                                    , watcher.checkView
                                        100
                                        (Test.Html.Query.has
                                            [ Test.Html.Selector.exactText "AT"
                                            , Test.Html.Selector.exactText "Stevie Steve"
                                            , Test.Html.Selector.exactText "Joe"
                                            , Test.Html.Selector.text "Moves"
                                            , Test.Html.Selector.text "played AA (+8)"
                                            ]
                                        )
                                    , userB.snapshotView 100 { name = "userB's perspective" }
                                    , watcher.snapshotView 100 { name = "Spectator's perspective" }
                                    ]

                                _ ->
                                    [ T.checkState 0 (\_ -> Err "Expected one word spelling game in the guild channel") ]
                        )
                    ]
                )
            ]
        , E2EHelper.startTest
            "Turn notifications in a DM match"
            E2EHelper.startTime
            normalConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.tallDesktopWindow
                (\admin user ->
                    -- `user` has push notifications enabled (see connectTwoUsersAndJoinNewGuild).
                    [ -- Admin creates a Word Spelling Game match in the DM with the other user.
                      admin.click 100 (Dom.id "guild_openDm_2")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.click 100 (Dom.id "wsg_advancedSection")
                    , admin.input 100 (Dom.id "wsg_lettersInput") "AADEEIILMNNOORRSSTT"
                    , admin.click 100 (Dom.id "wsg_start")

                    -- The other user opens the match, joins it, and then navigates away.
                    , user.click 2000 (Dom.id "guild_openDm_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.click 100 (Dom.id "wordSpellingGame_joinGame")
                    , user.click 100 (Dom.id "guildIcon_showFriends")

                    -- Admin swaps their tiles, passing the turn to the user. The user isn't
                    -- viewing the game so they get a push notification about their turn that
                    -- includes what the admin just did.
                    , admin.click 100 (Dom.id "wordSpellingGame_replaceTray")
                    , E2EHelper.checkNotification "Your turn!" "AT swapped their tiles. It's your turn in the Word Spelling Game."

                    -- The user comes back to the game and swaps their own tiles, then admin swaps
                    -- again so it's the user's turn once more. This time the user is viewing the
                    -- game, so no new notification may be sent. checkNotification fails when more
                    -- than one notification matches the body, so passing again proves only the
                    -- original notification exists.
                    , user.click 100 (Dom.id "guild_friendLabel_0")
                    , user.click 100 (Dom.id "guild_openGamesTab")
                    , user.input 100 (Dom.id "go_matchSwitcher") "0"
                    , user.click 100 (Dom.id "wordSpellingGame_replaceTray")
                    , admin.click 100 (Dom.id "wordSpellingGame_replaceTray")
                    , E2EHelper.checkNotification "Your turn!" "AT swapped their tiles. It's your turn in the Word Spelling Game."
                    ]
                )
            ]
        , E2EHelper.startTest
            "Turn and game-end notifications in a guild channel match"
            E2EHelper.startTime
            normalConfig
            [ E2EHelper.connectFourUsersAndJoinNewGuild
                E2EHelper.tallDesktopWindow
                (\admin userA userB watcher ->
                    [ -- Give everyone except the admin push notifications. (Three "Push
                      -- notifications enabled" pushes are sent, so that body can't be asserted
                      -- with checkNotification here.)
                      E2EHelper.enableNotifications False userA
                    , E2EHelper.enableNotifications False userB
                    , E2EHelper.enableNotifications False watcher

                    -- Admin creates a match with a 2-tile tray and a bag of exactly six A tiles:
                    -- the three players drain the bag when joining, so every turn is a pass and
                    -- the third pass in a row ends the game.
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                    , admin.click 100 (Dom.id "wsg_advancedSection")
                    , admin.input 100 (Dom.id "wsg_traySizeInput") "2"
                    , admin.input 100 (Dom.id "wsg_lettersInput") "AAAAAA"
                    , admin.click 100 (Dom.id "wsg_start")
                    , T.andThen
                        100
                        (\state ->
                            case guildChannelGames state.backend of
                                [ ( matchId, _ ) ] ->
                                    [ -- The second and third members open the match from its
                                      -- message card and join it. The fourth member never joins.
                                      userA.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString matchId))
                                    , userA.click 100 (Dom.id "wordSpellingGame_joinGame")
                                    , userB.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString matchId))
                                    , userB.click 100 (Dom.id "wordSpellingGame_joinGame")

                                    -- Everyone but the admin navigates away from the game.
                                    , userA.click 100 (Dom.id "guildIcon_showFriends")
                                    , userB.click 100 (Dom.id "guildIcon_showFriends")
                                    , watcher.click 100 (Dom.id "guildIcon_showFriends")

                                    -- Admin passes, so it's the second player's turn. Both joined
                                    -- players are away, but only the player whose turn it now is
                                    -- gets notified: checkNotification fails if the body matches
                                    -- more than one notification, so it also proves the third
                                    -- player wasn't notified with the same text.
                                    , admin.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                                    , E2EHelper.checkNotification "Your turn!" "AT passed. It's your turn in the Word Spelling Game."

                                    -- The second player comes back, passes, and leaves again. Now
                                    -- the third player (still away) gets their turn notification.
                                    , userA.click 100 (Dom.id "guild_openGuild_1")
                                    , userA.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString matchId))
                                    , userA.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                                    , E2EHelper.checkNotification "Your turn!" "Stevie Steve passed. It's your turn in the Word Spelling Game."
                                    , userA.click 100 (Dom.id "guildIcon_showFriends")

                                    -- The third player comes back and passes, which ends the game
                                    -- (everyone passed in turn). Every *player* should be told the
                                    -- game ended, but only the second player is both away and a
                                    -- player: the admin is viewing the game, the third player just
                                    -- made the final move, and the watcher never joined. So
                                    -- exactly one game-over notification must exist.
                                    , userB.click 100 (Dom.id "guild_openGuild_1")
                                    , userB.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString matchId))
                                    , userB.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                                    , E2EHelper.checkNotification "Game over" "Joe passed. The game has ended. AT and Stevie Steve and Joe tied with 0 points!"
                                    ]

                                _ ->
                                    [ T.checkState 0 (\_ -> Err "Expected one word spelling game in the guild channel") ]
                        )
                    ]
                )
            ]
        , wordDefinitions normalConfig
        ]


{-| Clicking a played word in the Moves log looks up its dictionary definition. On a wide screen it
appears in a column to the right of the status view; on a narrower one it overlays the board, with a
close button, and is also dismissed when the player grabs a tray tile. This covers both layouts.
-}
wordDefinitions :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
wordDefinitions normalConfig =
    T.testGroup
        "Word definitions"
        [ wordDefinitionColumnTest normalConfig
        , wordDefinitionOverlayTest normalConfig
        ]


{-| Board/tray geometry helpers for a desktop window `boardXOffset` px from the viewport's left
edge (i.e. its `channelAndGuildColumnWidth`). Cells are 30px and tray tiles 54px apart, as in the
other desktop tests; only the horizontal offset changes with the window width.
-}
desktopTrayTile : Int -> Float -> ( Float, Float )
desktopTrayTile boardXOffset index =
    ( toFloat boardXOffset + 25 + index * 54, toFloat (WordSpellingGame.boardY + 15 * 30) )


desktopBoardCell : Int -> Int -> Int -> ( Float, Float )
desktopBoardCell boardXOffset cx cy =
    ( toFloat (boardXOffset + 15 + cx * 30), toFloat (WordSpellingGame.boardY + cy * 30) )


{-| Set up a solo Word Spelling Game and place "LOAD" through the centre square, leaving one
`Description_PlacedWord` row in the Moves log to click. `boardXOffset` is the window's
`channelAndGuildColumnWidth` (258 at 1000px wide, 338 at 1400px).
-}
placeLoadSolo :
    Int
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
placeLoadSolo boardXOffset admin =
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

        dragTile delay from to =
            T.group
                [ admin.custom delay (Dom.id "elm-ui-root-id") "pointerdown" (pointerEvent from)
                , admin.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerEvent to)
                , admin.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerEvent to)
                , admin.custom 100 (Dom.id "elm-ui-root-id") "pointerup" pointerUpEvent
                ]
    in
    [ -- Admin creates a Word Spelling Game match in the DM and places LOAD solo (their fresh tray is
      -- "A O A L D O M", so LOAD is slots 3,1,0,4 across the centre row).
      admin.click 100 (Dom.id "guild_openDm_2")
    , admin.click 100 (Dom.id "guild_openGamesTab")
    , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
    , admin.click 100 (Dom.id "wsg_advancedSection")
    , admin.input 100 (Dom.id "wsg_lettersInput") "AADEEIILMNNOORRSSTT"
    , admin.click 100 (Dom.id "wsg_start")
    , dragTile 100 (desktopTrayTile boardXOffset 3) (desktopBoardCell boardXOffset 6 7)
    , dragTile 100 (desktopTrayTile boardXOffset 1) (desktopBoardCell boardXOffset 7 7)
    , dragTile 100 (desktopTrayTile boardXOffset 0) (desktopBoardCell boardXOffset 8 7)
    , dragTile 100 (desktopTrayTile boardXOffset 4) (desktopBoardCell boardXOffset 9 7)
    , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_6_7")
    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "played LOAD (+10)" ])
    ]


{-| On a wide screen, clicking the played "LOAD" row shows its dictionary definition in a column to
the right of the status view.
-}
wordDefinitionColumnTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
wordDefinitionColumnTest normalConfig =
    E2EHelper.startTest
        "Word definition in a right-hand column"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            -- 1400px is wide enough (>= 1300) for the definition column; at this width the board sits
            -- 338px (channelAndGuildColumnWidth) from the left.
            { width = 1400, height = 1300 }
            (\admin _ ->
                placeLoadSolo 338 admin
                    ++ [ -- No definition column before a word is clicked.
                         admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_wordDefinition" ])

                       -- Clicking the move row opens the definition column and fetches the definition.
                       , admin.click 100 (Dom.id "wsg_moveWord_1")
                       , admin.checkView 1000 (Test.Html.Query.has [ Test.Html.Selector.id "wsg_wordDefinition" ])
                       , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text "noun"
                                , Test.Html.Selector.text "A burden; a weight to be carried."
                                , Test.Html.Selector.id "wsg_closeWordDefinition"
                                ]
                            )
                       , admin.snapshotView 100 { name = "Word definition column" }

                       -- The close button dismisses the column.
                       , admin.click 100 (Dom.id "wsg_closeWordDefinition")
                       , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_wordDefinition" ])
                       ]
            )
        ]


{-| On a narrower screen, clicking the played "LOAD" row overlays its definition on the board. The
overlay has a close button and is also dismissed when the player interacts with their tray.
-}
wordDefinitionOverlayTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
wordDefinitionOverlayTest normalConfig =
    let
        pointerDown : ( Float, Float ) -> Json.Encode.Value
        pointerDown ( x, y ) =
            Json.Encode.object
                [ ( "timeStamp", Json.Encode.float 0 )
                , ( "pointerId", Json.Encode.int 0 )
                , ( "clientX", Json.Encode.float x )
                , ( "clientY", Json.Encode.float y )
                ]
    in
    E2EHelper.startTest
        "Word definition overlaid on the board"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            -- 1000px is below the 1300px column threshold, so the definition overlays the board. The
            -- board sits 258px from the left here.
            E2EHelper.tallDesktopWindow
            (\admin _ ->
                placeLoadSolo 258 admin
                    ++ [ -- Clicking the move row overlays the definition on the board with a close button.
                         admin.click 100 (Dom.id "wsg_moveWord_1")
                       , admin.checkView 1000 (Test.Html.Query.has [ Test.Html.Selector.id "wsg_wordDefinition" ])
                       , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text "A burden; a weight to be carried."
                                , Test.Html.Selector.id "wsg_closeWordDefinition"
                                ]
                            )
                       , admin.snapshotView 100 { name = "Word definition overlay" }

                       -- The close button dismisses the overlay.
                       , admin.click 100 (Dom.id "wsg_closeWordDefinition")
                       , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_wordDefinition" ])

                       -- Re-open it, then grabbing a tray tile dismisses it. A drag is only recognised
                       -- once the pointer moves after going down, so send both.
                       , admin.click 100 (Dom.id "wsg_moveWord_1")
                       , admin.checkView 1000 (Test.Html.Query.has [ Test.Html.Selector.id "wsg_wordDefinition" ])
                       , admin.custom 100 (Dom.id "elm-ui-root-id") "pointerdown" (pointerDown (desktopTrayTile 258 0))
                       , admin.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerDown (desktopTrayTile 258 0))
                       , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_wordDefinition" ])
                       ]
            )
        ]


{-| All games stored in guild channels (as opposed to DM channels) on the backend.
-}
guildChannelGames : BackendModel -> List ( Id ChannelMessageId, Game.BackendGameData )
guildChannelGames backend =
    SeqDict.values backend.guilds
        |> List.concatMap (\guild -> SeqDict.values guild.channels)
        |> List.concatMap (\channel -> SeqDict.toList channel.games)


{-| All games stored in DM channels on the backend.
-}
dmChannelGames : BackendModel -> List ( Id ChannelMessageId, Game.BackendGameData )
dmChannelGames backend =
    SeqDict.values backend.dmChannels
        |> List.concatMap (\channel -> SeqDict.toList channel.games)


{-| The shared state of the single word spelling game running in a DM channel.
-}
dmWordSpellingShared : BackendModel -> Result String WordSpellingGame.Shared
dmWordSpellingShared backend =
    case dmChannelGames backend of
        [ ( _, Game.GameData_WordSpellingGame _ _ shared ) ] ->
            Ok shared

        _ ->
            Err "Expected one word spelling game in a DM channel"


{-| Assert the shared state of a word spelling game between AT (the match creator, always the
first player) and one other player: whose turn it is, which cells are and aren't committed to the
board, and the second player's score, tray size and stored premove (which, when expected, must
also have passed backend validation).
-}
checkGame :
    { turnCount : Int
    , boardSize : Int
    , committedCells : List ( Int, Int )
    , emptyCells : List ( Int, Int )
    , userScore : Int
    , userTraySize : Int
    , userHasPremove : Bool
    }
    -> WordSpellingGame.Shared
    -> Result String ()
checkGame expected shared =
    case List.Nonempty.toList shared.players of
        [ _, userPlayer ] ->
            if shared.turnCount /= expected.turnCount then
                Err
                    ("Expected turnCount "
                        ++ String.fromInt expected.turnCount
                        ++ " but got "
                        ++ String.fromInt shared.turnCount
                    )

            else if SeqDict.size shared.board /= expected.boardSize then
                Err
                    ("Expected "
                        ++ String.fromInt expected.boardSize
                        ++ " tiles on the board but got "
                        ++ String.fromInt (SeqDict.size shared.board)
                    )

            else if List.any (\cell -> not (SeqDict.member cell shared.board)) expected.committedCells then
                Err "A cell that should hold a committed tile is empty"

            else if List.any (\cell -> SeqDict.member cell shared.board) expected.emptyCells then
                Err "A cell that should be empty holds a committed tile"

            else if userPlayer.score /= expected.userScore then
                Err
                    ("Expected the second player to have "
                        ++ String.fromInt expected.userScore
                        ++ " points but got "
                        ++ String.fromInt userPlayer.score
                    )

            else if IdArray.length userPlayer.tray /= expected.userTraySize then
                Err
                    ("Expected the second player to hold "
                        ++ String.fromInt expected.userTraySize
                        ++ " letters but got "
                        ++ String.fromInt (IdArray.length userPlayer.tray)
                    )

            else
                case ( expected.userHasPremove, userPlayer.premove ) of
                    ( True, Just ( _, _, WordSpellingGame.IsValid _ ) ) ->
                        Ok ()

                    ( True, Just ( _, _, WordSpellingGame.IsNotValid ) ) ->
                        Err "Expected the second player's premove to have passed backend validation"

                    ( True, Nothing ) ->
                        Err "Expected the second player to have a stored premove"

                    ( False, Just _ ) ->
                        Err "Expected the second player to have no stored premove"

                    ( False, Nothing ) ->
                        Ok ()

        _ ->
            Err "Expected exactly two players"


{-| Assert the current turn and the number of place-word attempts left for the single word spelling
game running in a DM channel.
-}
checkWordSpellingState : { turnCount : Int, attemptsLeft : Int } -> BackendModel -> Result String ()
checkWordSpellingState expected backend =
    case dmChannelGames backend of
        [ ( _, Game.GameData_WordSpellingGame _ _ shared ) ] ->
            if shared.turnCount /= expected.turnCount then
                Err
                    ("Expected turnCount "
                        ++ String.fromInt expected.turnCount
                        ++ " but got "
                        ++ String.fromInt shared.turnCount
                    )

            else if OneOrGreater.toInt shared.attemptsLeft /= expected.attemptsLeft then
                Err
                    ("Expected "
                        ++ String.fromInt expected.attemptsLeft
                        ++ " attempts left but got "
                        ++ String.fromInt (OneOrGreater.toInt shared.attemptsLeft)
                    )

            else
                Ok ()

        _ ->
            Err "Expected one word spelling game in a DM channel"


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


wordSpellingGamePremove :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
wordSpellingGamePremove normalConfig =
    E2EHelper.startTest
        "Word spelling premove"
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

                -- Cancel from the setup screen returns to the game select view.
                , admin.click 100 (Dom.id "wsg_cancel")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "wsg_start" ])
                , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.GameType_WordSpellingGame))
                , admin.click 100 (Dom.id "wsg_advancedSection")
                , admin.input 100 (Dom.id "wsg_lettersInput") "AADEEIILMNNOORRSSTT"
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
                    [ user.checkModel 100 (checkPopCount 11)
                    , dragTile 100 user (trayTile 4) (boardCell 7 6)
                    , dragTile 100 user (trayTile 3) (boardCell 7 8)
                    , user.click 100 (Dom.id "wordSpellingGame_submitLine_v_7_6")
                    , admin.snapshotView 5000 { name = "Place \"rot\"" }
                    , user.snapshotView 0 { name = "Place \"rot\"" }
                    ]
                , T.collapsableGroup
                    "Premove \"dirt\""
                    [ dragTile 100 user (trayTile 0) (boardCell 9 8)
                    , dragTile 100 user (trayTile 5) (boardCell 9 9)
                    , dragTile 100 user (trayTile 6) (boardCell 9 10)
                    , user.click 100 (Dom.id "wsg_submitPremove_v_9_8")
                    , user.snapshotView 5000 { name = "Place \"dirt\"" }
                    ]
                , T.collapsableGroup
                    "Place \"rote\""
                    [ dragTile 100 admin (trayTile 1) (boardCell 7 9)
                    , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_7_9")
                    ]
                , -- Handing the turn to the user plays their premoved DIRT right away: the word is
                  -- committed to the board, the premove is cleared, and the turn passes straight
                  -- back to AT (turnCount 4 with two players = player 0, the match creator).
                  T.checkState
                    1000
                    (\state ->
                        dmWordSpellingShared state.backend
                            |> Result.andThen
                                (checkGame
                                    { turnCount = 4
                                    , boardSize = 10
                                    , committedCells = [ ( 9, 8 ), ( 9, 9 ), ( 9, 10 ) ]
                                    , emptyCells = []
                                    , userScore = 10
                                    , userTraySize = 3
                                    , userHasPremove = False
                                    }
                                )
                    )
                , -- Both clients show it's AT's turn again (AT is on 14 points: 10 for LOAD plus
                  -- 4 for ROTE).
                  admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "AT", Test.Html.Selector.exactText "'s turn (14)" ]
                    )
                , user.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "AT", Test.Html.Selector.exactText "'s turn (14)" ]
                    )
                , T.collapsableGroup
                    "Premove \"rotes\" is cancelled by a move that affects it"
                    [ -- Playing DIRT left the user holding I S S (the bag is empty, so nothing
                      -- was drawn) — the premoved tiles are gone and the remaining three tiles
                      -- keep their tray slots 1..3, showing I, S, S. While AT is on turn, the
                      -- user premoves the S in slot 2 below ROTE, extending it to ROTES.
                      dragTile 100 user (trayTile 2) (boardCell 7 10)
                    , user.click 100 (Dom.id "wsg_submitPremove_h_7_10")
                    , T.checkState
                        1000
                        (\state ->
                            dmWordSpellingShared state.backend
                                |> Result.andThen
                                    (checkGame
                                        { turnCount = 4
                                        , boardSize = 10
                                        , committedCells = []
                                        , emptyCells = [ ( 7, 10 ) ]
                                        , userScore = 10
                                        , userTraySize = 3
                                        , userHasPremove = True
                                        }
                                    )
                        )
                    , -- Admin plays their A left of DIRT's T, spelling AT. The new tile lands
                      -- right next to the premoved S's cell, so the S would now also spell SAT —
                      -- a word the backend never validated — meaning the premove's outcome has
                      -- been affected and it must be cancelled instead of played: no tile appears
                      -- at (7,10), the user keeps their letters and score, and the turn passes to
                      -- them normally (turnCount 5 = player 1).
                      dragTile 100 admin (trayTile 2) (boardCell 8 10)
                    , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_8_10")
                    , T.checkState
                        1000
                        (\state ->
                            dmWordSpellingShared state.backend
                                |> Result.andThen
                                    (checkGame
                                        { turnCount = 5
                                        , boardSize = 11
                                        , committedCells = [ ( 8, 10 ) ]
                                        , emptyCells = [ ( 7, 10 ) ]
                                        , userScore = 10
                                        , userTraySize = 3
                                        , userHasPremove = False
                                        }
                                    )
                        )
                    , user.snapshotView 100 { name = "Premove cancelled" }
                    ]
                ]
            )
        ]
