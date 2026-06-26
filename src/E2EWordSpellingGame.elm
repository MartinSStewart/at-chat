module E2EWordSpellingGame exposing (wordSpellingGameTests)

import E2EHelper exposing (..)
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Json.Encode
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


wordSpellingGameTests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
wordSpellingGameTests normalConfig =
    startTest
        "Word spelling game match"
        startTime
        normalConfig
        [ connectTwoUsersAndJoinNewGuild
            tallDesktopWindow
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
                        ( toFloat (283 + index * 54), 573 )

                    boardCell : Int -> Int -> ( Float, Float )
                    boardCell cx cy =
                        ( toFloat (273 + cx * 30), toFloat (113 + cy * 30) )
                in
                [ -- Admin creates a Word Spelling Game match in the DM with the other user.
                  admin.click 100 (Dom.id "guild_openDm_2")
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Word Spelling Game")
                , admin.click 100 (Dom.id "wsg_start")

                -- The other user opens the same match and joins it.
                , user.click 100 (Dom.id "guild_openDm_0")
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
                , dragTile 1000 user (trayTile 0) (boardCell 7 6)
                ]
            )
        ]
