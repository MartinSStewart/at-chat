module E2EWordSpellingGame exposing (wordSpellingGameTests)

import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Game
import Json.Encode
import Message
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendModel_, FrontendMsg, FrontendMsg_, ToBackend, ToFrontend)
import WordSpellingGame


wordSpellingGameTests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
wordSpellingGameTests normalConfig =
    E2EHelper.startTest
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
                ]
            )
        ]
