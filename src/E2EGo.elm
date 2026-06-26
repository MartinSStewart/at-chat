module E2EGo exposing
    ( goMatchTest
    , goTimeoutTest
    , goTurnNotificationDotTest
    , publicGoMatchViewTest
    )

import E2EHelper exposing (..)
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Env
import Json.Decode
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


goMatchTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
goMatchTest normalConfig =
    startTest
        "Two users play a Go match, one leaves and rejoins, then start a new match"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            tallDesktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_2")
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , admin.click 100 (Dom.id "game_select_Go")
                        , admin.click 100 (Dom.id "go_start")
                        , user.click 100 (Dom.id "guild_gameStartedCard_0")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])

                        -- A couple of opening moves: admin is Black (creator default), user is White
                        , admin.click 100 (Dom.id "go_cell_4_4")
                        , user.click 100 (Dom.id "go_cell_5_4")
                        , admin.click 100 (Dom.id "go_cell_4_5")
                        , user.click 100 (Dom.id "go_cell_5_5")

                        -- User leaves the game by navigating back out of the DM
                        , user.navigateBack 100

                        -- ... and then rejoins by clicking back into the DM and the Go tab
                        , T.connectFrontend
                            100
                            sessionId1
                            "/"
                            tallDesktopWindow
                            (\user2 ->
                                [ user2.portEvent 10 "load_startup_data_from_js" (startupDataJson firefoxDesktop)
                                , user2.click 100 (Dom.id "guild_friendLabel_0")
                                , user2.click 100 (Dom.id "guild_openGamesTab")
                                , user2.click 100 (Dom.id "game_select_Go")
                                , user2.input 100 (Dom.id "go_matchSwitcher") "0"

                                -- A few more moves to confirm the state persisted
                                , admin.click 100 (Dom.id "go_cell_3_3")
                                , user2.click 100 (Dom.id "go_cell_3_4")

                                -- Wrap up the game: pass twice, finish marking, agree on scoring
                                , admin.click 100 (Dom.id "go_pass")
                                , user2.click 100 (Dom.id "go_pass")
                                , admin.click 1000 (Dom.id "go_cell_3_6")
                                , admin.click 1000 (Dom.id "go_doneMarking")
                                , user2.click 1000 (Dom.id "go_agree")
                                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Final score" ])
                                , user2.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Final score" ])

                                -- Start a fresh match after the game has ended
                                , admin.click 100 (Dom.id "go_reset")
                                , admin.click 100 (Dom.id "go_start")
                                , user2.click 100 (Dom.id "guild_gameStartedCard_1")
                                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                                , user2.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                                , admin.click 2000 (Dom.id "go_cell_3_3")
                                , user2.click 2000 (Dom.id "go_cell_3_4")
                                , admin.click 2000 (Dom.id "go_pass")
                                , user2.click 2000 (Dom.id "go_pass")
                                , admin.click 2000 (Dom.id "go_cell_3_6")
                                , admin.click 2000 (Dom.id "go_doneMarking")
                                , user2.click 2000 (Dom.id "go_disagree")
                                , admin.click 2000 (Dom.id "go_cell_3_5")
                                ]
                            )
                        ]
                    )
                ]
            )
        ]


goTimeoutTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
goTimeoutTest normalConfig =
    startTest
        "A player who runs out of time can't move, and both players see the loss-on-time result"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            tallDesktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_2")
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , admin.click 100 (Dom.id "game_select_Go")

                        -- Set up a very short time control: 1 minute main time, no increment.
                        , admin.input 100 (Dom.id "go_mainTimeInput") "1"
                        , admin.input 100 (Dom.id "go_incrementInput") "0"
                        , admin.click 100 (Dom.id "go_start")
                        , user.click 100 (Dom.id "guild_gameStartedCard_0")

                        -- Admin is Black (creator default) and moves first. This starts
                        -- White's clock ticking, and both players see it's White's turn.
                        , admin.click 100 (Dom.id "go_cell_4_4")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "White to move" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "White to move" ])

                        -- Both players agree a single move has been played so far.
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "1 / 1" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "1 / 1" ])

                        -- Let 70 seconds pass (more than White's 60 second clock) and then
                        -- have White (the user) try to place a stone. The move must be rejected
                        -- because White has run out of time.
                        , user.click 70000 (Dom.id "go_cell_5_4")

                        -- The rejected move means no new stone was added: both players still
                        -- only see a single move in the history.
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "1 / 1" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "1 / 1" ])
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "2 / 2" ])
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "2 / 2" ])

                        -- Both players see the same loss-on-time result.
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "Black wins! White loses on time." ])
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "Black wins! White loses on time." ])

                        -- And neither player still sees a "to move" prompt.
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "White to move" ])
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "White to move" ])
                        ]
                    )
                ]
            )
        ]


goTurnNotificationDotTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
goTurnNotificationDotTest normalConfig =
    startTest
        "Go channel header shows a red dot when it's the user's turn and they aren't viewing the match"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            tallDesktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_2")
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , admin.click 100 (Dom.id "game_select_Go")
                        , admin.click 100 (Dom.id "go_start")
                        , user.click 100 (Dom.id "guild_gameStartedCard_0")

                        -- No dot for either user yet: admin is viewing the match,
                        -- and even though it's admin's turn, the user has no move pending
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- Admin (Black) makes a move; now it's user's (White) turn
                        , admin.click 100 (Dom.id "go_cell_4_4")

                        -- User is still on the Go tab so no dot
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- User leaves the Go tab by switching to the chat description tab
                        , user.click 100 (Dom.id "guild_openDescription")

                        -- The dot should now appear since it's user's turn and they aren't viewing the match
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- Admin still has no pending turn so no dot
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- User clicks back to the Go tab; the dot disappears
                        , user.click 100 (Dom.id "guild_openGamesTab")
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- User makes their move; now it's admin's turn
                        , user.click 100 (Dom.id "go_cell_5_4")

                        -- Admin is viewing the match so no dot for them
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_goMatchTurnDot" ])

                        -- Admin switches away from the Go tab and should now see the dot
                        , admin.click 100 (Dom.id "guild_openDescription")
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_goMatchTurnDot" ])
                        ]
                    )
                ]
            )
        ]


publicGoMatchViewTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
publicGoMatchViewTest normalConfig =
    startTest
        "A player shares a Go match link so a non-logged-in spectator can view it"
        startTime
        normalConfig
        [ T.connectFrontend
            100
            sessionId0
            "/"
            tallDesktopWindow
            (\admin ->
                [ handleLogin firefoxDesktop adminEmail admin
                , inviteUser
                    admin
                    (\user ->
                        [ T.connectFrontend
                            100
                            sessionId4
                            "/go-match/does-not-exist"
                            tallDesktopWindow
                            (\missingViewer ->
                                [ missingViewer.portEvent 10 "load_startup_data_from_js" (startupDataJson firefoxDesktop)
                                , missingViewer.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Go match not found" ])
                                ]
                            )
                        , user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_2")
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , admin.click 100 (Dom.id "game_select_Go")
                        , admin.click 100 (Dom.id "go_start")
                        , admin.click 100 (Dom.id "go_cell_4_4")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "go_share" ])
                        , admin.click 100 (Dom.id "go_share")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "go_share" ])
                        , admin.click 100 (Dom.id "go_shareLink_copy")
                        , T.andThen
                            100
                            (\data ->
                                let
                                    copyRequests =
                                        List.filter
                                            (\portRequest -> portRequest.portName == "copy_to_clipboard_to_js")
                                            data.portRequests
                                in
                                case copyRequests |> List.head of
                                    Just portRequest ->
                                        case Json.Decode.decodeValue Json.Decode.string portRequest.value of
                                            Ok shareUrl ->
                                                if String.startsWith Env.domain shareUrl then
                                                    [ T.connectFrontend
                                                        100
                                                        sessionId2
                                                        (String.dropLeft (String.length Env.domain) shareUrl)
                                                        tallDesktopWindow
                                                        (\viewer ->
                                                            [ viewer.portEvent 10 "load_startup_data_from_js" (startupDataJson firefoxDesktop)
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.has [ Test.Html.Selector.id "public_go_container" ])
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.hasNot [ Test.Html.Selector.id "go_pass" ])
                                                            , tallSnapshot viewer 100 { name = "Spectating Go match" }
                                                            ]
                                                        )
                                                    ]

                                                else
                                                    [ admin.checkModel 100 (\_ -> Err ("Share URL didn't start with domain: " ++ shareUrl)) ]

                                            Err _ ->
                                                [ admin.checkModel 100 (\_ -> Err "Failed to decode share URL port value") ]

                                    Nothing ->
                                        [ admin.checkModel 100 (\_ -> Err "Expected a copy_to_clipboard_to_js port request after pressing share") ]
                            )
                        ]
                    )
                ]
            )
        ]
