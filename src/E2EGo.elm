module E2EGo exposing
    ( goGuildMatchTest
    , goMatchTest
    , goTimeoutTest
    , goTurnNotificationDotTest
    , publicGoMatchViewTest
    , tests
    )

import Array exposing (Array)
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Env
import Game
import Go
import Id exposing (ChannelMessageId, Id)
import Json.Decode
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


tests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
tests normalConfig =
    T.testGroup
        "Go matches"
        [ goMatchTest normalConfig
        , goGuildMatchTest normalConfig
        , goTimeoutTest normalConfig
        , goTurnNotificationDotTest normalConfig
        , publicGoMatchViewTest normalConfig
        , E2EHelper.startTest
            "Single player go"
            E2EHelper.startTime
            normalConfig
            [ T.connectFrontend
                100
                E2EHelper.sessionId0
                "/"
                E2EHelper.tallDesktopWindow
                (\admin ->
                    [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                    , admin.click 1000 (Dom.id "guild_friendLabel_0")
                    , admin.click 100 (Dom.id "guild_openGamesTab")
                    , admin.click 100 (Dom.id "game_select_Go")
                    , admin.click 100 (Dom.id "go_start")
                    , admin.click 100 (Dom.id "go_cell_4_4")
                    , admin.click 100 (Dom.id "go_cell_5_4")
                    , admin.snapshotView 10000 { name = "Single player go" }
                    , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.exactText "9:55", Test.Html.Selector.exactText "10:05" ])
                    ]
                )
            ]
        ]


goMatchTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
goMatchTest normalConfig =
    E2EHelper.startTest
        "Two users play a Go match, one leaves and rejoins, then start a new match"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_2")
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , admin.click 100 (Dom.id "game_select_Go")
                        , admin.click 100 (Dom.id "go_start")
                        , user.click 100 (Dom.id "guild_gameStartedCard_0")
                        , user.click 100 (Dom.id "go_joinGame")
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
                            E2EHelper.sessionId1
                            "/"
                            E2EHelper.tallDesktopWindow
                            (\user2 ->
                                [ user2.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson E2EHelper.firefoxDesktop)
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

                                -- Start a fresh match after the game has ended. The match switcher
                                -- (and its setup view) is only shown when no match is selected, so
                                -- close the games tab and reopen it to get back to the setup view.
                                , admin.click 100 (Dom.id "guild_openDescription")
                                , admin.click 100 (Dom.id "guild_openGamesTab")
                                , admin.click 100 (Dom.id "go_start")
                                , user2.click 100 (Dom.id "guild_gameStartedCard_1")
                                , user2.click 100 (Dom.id "go_joinGame")
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
    E2EHelper.startTest
        "A player who runs out of time can't move, and both players see the loss-on-time result"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
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
                        , user.click 100 (Dom.id "go_joinGame")

                        -- Admin is Black (creator default) and moves first. Both players see
                        -- it's White's turn, but White's clock isn't ticking yet: the clocks
                        -- only start once both players have made a move.
                        , admin.click 100 (Dom.id "go_cell_4_4")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "White to move" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "White to move" ])

                        -- Both players agree a single move has been played so far.
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "1 / 1" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "1 / 1" ])

                        -- White takes 70 seconds (more than the 60 second main time) over their
                        -- first move and it still counts, since the clocks haven't started.
                        , user.click 70000 (Dom.id "go_cell_5_4")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "2 / 2" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "2 / 2" ])

                        -- Both players have moved now, so the clocks are live. Black replies
                        -- quickly, and then White lets their clock run out.
                        , admin.click 100 (Dom.id "go_cell_4_5")
                        , user.click 70000 (Dom.id "go_cell_5_5")

                        -- The rejected move means no new stone was added: both players still
                        -- only see three moves in the history.
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "3 / 3" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "3 / 3" ])
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "4 / 4" ])
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "4 / 4" ])

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
    E2EHelper.startTest
        "Go channel header shows a red dot when it's the user's turn and they aren't viewing the match"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , admin.click 100 (Dom.id "guild_openDm_2")
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , admin.click 100 (Dom.id "game_select_Go")
                        , admin.click 100 (Dom.id "go_start")
                        , user.click 100 (Dom.id "guild_gameStartedCard_0")
                        , user.click 100 (Dom.id "go_joinGame")

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


goGuildMatchTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
goGuildMatchTest normalConfig =
    E2EHelper.startTest
        "Two guild members play a Go match in a guild channel"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.tallDesktopWindow
            (\admin user ->
                [ -- Both users start out viewing the guild's first channel.
                  admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Go")
                , admin.click 100 (Dom.id "go_start")
                , T.checkState
                    100
                    (\state ->
                        case guildChannelGoGames state.backend of
                            [ ( _, _, actions ) ] ->
                                if Go.joinedUser actions == Nothing then
                                    Ok ()

                                else
                                    Err "No one should have joined the match yet"

                            _ ->
                                Err "Expected one Go match in the guild channel"
                    )
                , T.andThen
                    100
                    (\state ->
                        case guildChannelGoGames state.backend of
                            [ ( matchId, setup, _ ) ] ->
                                [ -- The other guild member opens the match from its message card and joins.
                                  user.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString matchId))
                                , user.click 100 (Dom.id "go_joinGame")
                                , T.checkState
                                    100
                                    (\state2 ->
                                        case guildChannelGoGames state2.backend of
                                            [ ( _, _, actions ) ] ->
                                                case Go.joinedUser actions of
                                                    Just joinedUserId ->
                                                        if joinedUserId == setup.createdBy then
                                                            Err "The creator should not have joined their own match"

                                                        else
                                                            Ok ()

                                                    Nothing ->
                                                        Err "Expected the other member to have joined the match"

                                            _ ->
                                                Err "Expected one Go match in the guild channel"
                                    )

                                -- Play an opening move each: admin is Black (creator default), user is White.
                                , admin.click 100 (Dom.id "go_cell_4_4")
                                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "White to move" ])
                                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "White to move" ])
                                , user.click 100 (Dom.id "go_cell_5_4")
                                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Black to move" ])
                                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Black to move" ])
                                ]

                            _ ->
                                [ T.checkState 0 (\_ -> Err "Expected one Go match in the guild channel") ]
                    )
                ]
            )
        ]


{-| All Go matches stored in guild channels (as opposed to DM channels) on the backend.
-}
guildChannelGoGames : BackendModel -> List ( Id ChannelMessageId, Go.ValidatedSetup, Array Go.ActionWithTime )
guildChannelGoGames backend =
    SeqDict.values backend.guilds
        |> List.concatMap (\guild -> SeqDict.values guild.channels)
        |> List.concatMap (\channel -> SeqDict.toList channel.games)
        |> List.filterMap
            (\( matchId, gameData ) ->
                case gameData of
                    Game.GameData_Go setup actions ->
                        Just ( matchId, setup, actions )

                    Game.GameData_WordSpellingGame _ _ _ ->
                        Nothing
            )


publicGoMatchViewTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
publicGoMatchViewTest normalConfig =
    E2EHelper.startTest
        "A player shares a Go match link so a non-logged-in spectator can view it"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ T.connectFrontend
                            100
                            E2EHelper.sessionId4
                            "/go-match/does-not-exist"
                            E2EHelper.tallDesktopWindow
                            (\missingViewer ->
                                [ missingViewer.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson E2EHelper.firefoxDesktop)
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
                                                        E2EHelper.sessionId2
                                                        (String.dropLeft (String.length Env.domain) shareUrl)
                                                        E2EHelper.tallDesktopWindow
                                                        (\viewer ->
                                                            [ viewer.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson E2EHelper.firefoxDesktop)
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.has [ Test.Html.Selector.id "public_go_container" ])
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.has [ Test.Html.Selector.text "to move" ])
                                                            , viewer.checkView
                                                                100
                                                                (Test.Html.Query.hasNot [ Test.Html.Selector.id "go_pass" ])
                                                            , E2EHelper.tallSnapshot viewer 100 { name = "Spectating Go match" }
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
