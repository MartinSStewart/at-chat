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
                , T.collapsableGroup
                    "Place invalid word"
                    [ dragTile 100 admin (trayTile 0) (boardCell 7 7)
                    , dragTile 100 admin (trayTile 1) (boardCell 8 7)
                    , dragTile 100 admin (trayTile 3) (boardCell 9 7)
                    , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_7_7")
                    , admin.snapshotView 3000 { name = "Place invalid word" }
                    , user.snapshotView 0 { name = "Place invalid word" }
                    ]
                , T.group
                    [ user.custom 100 (Dom.id "elm-ui-root-id") "pointerdown" (pointerEvent (trayTile 4))
                    , user.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerEvent (trayTile 4.1))
                    , user.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerEvent (trayTile 4.5))
                    , user.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerEvent (trayTile 5.5))
                    , user.custom 100 (Dom.id "elm-ui-root-id") "pointermove" (pointerEvent (trayTile 5.9))
                    , user.custom 100 (Dom.id "elm-ui-root-id") "pointerup" (pointerEvent (trayTile 5.9))
                    , user.snapshotView 500 { name = "Shift tray" }
                    ]
                , T.collapsableGroup
                    "Place \"site\""
                    [ dragTile 100 user (trayTile 6) (boardCell 7 6)
                    , dragTile 100 user (trayTile 4) (boardCell 7 7)
                    , dragTile 100 user (trayTile 5) (boardCell 7 8)
                    , dragTile 100 user (trayTile 1) (boardCell 7 9)
                    , user.click 100 (Dom.id "wordSpellingGame_submitLine_v_7_6")
                    , admin.snapshotView 5000 { name = "Place \"site\"" }
                    , user.snapshotView 0 { name = "Place \"site\"" }
                    ]
                , T.collapsableGroup
                    "Place \"said\""
                    [ dragTile 100 admin (trayTile 4) (boardCell 10 10)
                    , dragTile 100 admin (trayTile 3) (boardCell 9 10)
                    , dragTile 100 admin (trayTile 2) (boardCell 8 10)
                    , dragTile 100 admin (trayTile 1) (boardCell 7 10)
                    , admin.click 100 (Dom.id "wordSpellingGame_submitLine_h_7_10")
                    , admin.snapshotView 5000 { name = "Place \"said\"" }
                    , user.snapshotView 0 { name = "Place \"said\"" }
                    ]
                , T.collapsableGroup
                    "Place \"note\""
                    [ dragTile 100 user (trayTile 2) (boardCell 9 11)
                    , dragTile 100 user (trayTile 3) (boardCell 12 11)
                    , dragTile 100 user (trayTile 6) (boardCell 10 11)
                    , dragTile 100 user (trayTile 4) (boardCell 11 11)
                    , user.click 100 (Dom.id "wordSpellingGame_submitLine_h_9_11")
                    , admin.snapshotView 5000 { name = "Place \"note\"" }
                    , user.snapshotView 0 { name = "Place \"note\"" }
                    ]
                , T.collapsableGroup
                    "Place \"amino\""
                    [ dragTile 100 admin (trayTile 1) (boardCell 9 8)
                    , dragTile 100 admin (trayTile 6) (boardCell 9 9)
                    , dragTile 100 admin (trayTile 5) (boardCell 9 12)
                    , admin.click 100 (Dom.id "wordSpellingGame_submitLine_v_9_8")
                    , admin.snapshotView 5000 { name = "Place \"amino\"" }
                    , user.snapshotView 0 { name = "Place \"amino\"" }
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
                , user.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                , admin.click 100 (Dom.id "wordSpellingGame_passOrEndTurn")
                , admin.checkView
                    100
                    -- The leaderboard renders each player's name and score suffix as separate
                    -- elements (see WordSpellingGame.playerRow), so they're matched separately.
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "AT"
                        , Test.Html.Selector.exactText ": 28 (winner)"
                        , Test.Html.Selector.exactText "Stevie Steve"
                        , Test.Html.Selector.exactText ": 21"
                        ]
                    )
                , user.checkView
                    100
                    -- The leaderboard renders each player's name and score suffix as separate
                    -- elements (see WordSpellingGame.playerRow), so they're matched separately.
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "AT"
                        , Test.Html.Selector.exactText ": 28 (winner)"
                        , Test.Html.Selector.exactText "Stevie Steve"
                        , Test.Html.Selector.exactText ": 21"
                        ]
                    )
                ]
            )
        ]
