module E2EWordSpellingGame exposing (wordSpellingGameTests)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Game
import Json.Encode
import Message
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
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
                    windowSize : Coord CssPixels
                    windowSize =
                        Coord.xy E2EHelper.tallDesktopWindow.width E2EHelper.tallDesktopWindow.height

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

                    -- Drag a tile from one screen position to another. Two move events are
                    -- needed: the first transitions the drag into the Dragging state (which
                    -- records the start position), the second sets the drop position.
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
                    trayTile : Int -> ( Float, Float )
                    trayTile index =
                        ( toFloat (283 + index * 54), WordSpellingGame.trayY windowSize |> toFloat )

                    boardCell : Int -> Int -> ( Float, Float )
                    boardCell cx cy =
                        ( toFloat (273 + cx * 30), toFloat (WordSpellingGame.boardY + cy * 30) )
                in
                [ -- Admin creates a Word Spelling Game match in the DM with the other user.
                  admin.click 100 (Dom.id "guild_openDm_2")
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id ("game_select_" ++ Game.gameToString Message.Game_WordSpellingGame))
                , admin.click 100 (Dom.id "wsg_start")

                -- The other user opens the same match and joins it.
                , user.click 2000 (Dom.id "guild_openDm_0")
                , user.click 100 (Dom.id "guild_openGamesTab")
                , user.custom
                    100
                    (Dom.id "go_matchSwitcher")
                    "input"
                    (Json.Encode.object [ ( "target", Json.Encode.object [ ( "value", Json.Encode.string "0" ) ] ) ])
                , user.click 100 (Dom.id "wordSpellingGame_joinGame")

                -- Admin drags three tiles from the tray onto a row of the board to form a
                -- word, then submits it.
                , dragTile 100 admin (trayTile 0) (boardCell 7 7)
                , dragTile 100 admin (trayTile 1) (boardCell 8 7)
                , dragTile 100 admin (trayTile 3) (boardCell 9 7)
                , admin.click 100 (Dom.id "wordSpellingGame_submitWord")
                , dragTile 3000 user (trayTile 1) (boardCell 7 6)
                , dragTile 100 user (trayTile 5) (boardCell 7 7)
                , dragTile 100 user (trayTile 6) (boardCell 7 8)
                , user.click 100 (Dom.id "wordSpellingGame_submitWord")
                ]
            )
        ]
