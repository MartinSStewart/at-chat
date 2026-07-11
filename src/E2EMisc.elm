module E2EMisc exposing (handleNavigationHistoryOnMobile, inactiveThreadsAreHiddenTest, inviteUserAndDmChat)

import Audio
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Expect
import Id
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import Url


handleNavigationHistoryOnMobile :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
handleNavigationHistoryOnMobile config =
    E2EHelper.startTest
        "User clicks on push notification and is shown message"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.iphone14Window
            (\admin ->
                [ E2EHelper.handleMobilePwaLogin E2EHelper.adminEmail admin
                , E2EHelper.enableNotifications True admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , T.collapsableGroup
                            "First message"
                            [ E2EHelper.writeMessage user 100 "Hello admin!"
                            , T.andThen
                                100
                                (\data ->
                                    case
                                        List.filter
                                            (\notification -> notification.body == "Hello admin!")
                                            (E2EHelper.getNotifications data)
                                    of
                                        [ single ] ->
                                            case Url.fromString single.navigate of
                                                Just url ->
                                                    [ admin.update 100 (Audio.userMsg (Types.UrlChanged url))
                                                    , admin.checkView 100
                                                        (Test.Html.Query.has
                                                            [ Test.Html.Selector.exactText "Hello admin!"
                                                            , Test.Html.Selector.exactText "Write a message to Sven"
                                                            ]
                                                        )
                                                    , -- There shouldn't be anything to navigate back to. Mobile PWAs should stay at the first entry in the navigation history
                                                      admin.navigateBack 100
                                                    , admin.checkView 100
                                                        (Test.Html.Query.has
                                                            [ Test.Html.Selector.exactText "Hello admin!"
                                                            , Test.Html.Selector.exactText "Write a message to Sven"
                                                            ]
                                                        )
                                                    ]

                                                Nothing ->
                                                    [ T.checkState 0 (\_ -> Err "Message notification has malformed url") ]

                                        _ ->
                                            [ T.checkState 0 (\_ -> Err "Should be only one message notification") ]
                                )
                            ]
                        , T.collapsableGroup
                            "Second message"
                            [ E2EHelper.writeMessage user 1000 "Hello admin again!"
                            , T.andThen
                                100
                                (\data ->
                                    case
                                        List.filter
                                            (\notification -> notification.body == "Hello admin again!")
                                            (E2EHelper.getNotifications data)
                                    of
                                        [] ->
                                            [ admin.checkView 100
                                                (Test.Html.Query.has
                                                    [ Test.Html.Selector.exactText "Hello admin again!"
                                                    , Test.Html.Selector.exactText "Write a message to Sven"
                                                    ]
                                                )
                                            ]

                                        _ ->
                                            [ T.checkState 0 (\_ -> Err "There shouldn't be an additional notification since the admin is viewing the channel") ]
                                )
                            ]
                        , admin.click 100 (Dom.id "guild_headerBackButton")
                        , admin.click 1000 (Dom.id "guild_friendLabel_0")
                        , T.collapsableGroup
                            "Third message"
                            [ E2EHelper.writeMessage user 1000 "Hello admin 3!"
                            , T.andThen
                                100
                                (\data ->
                                    case
                                        List.filter
                                            (\notification -> notification.body == "Hello admin 3!")
                                            (E2EHelper.getNotifications data |> Debug.log "asdf")
                                    of
                                        [ single ] ->
                                            case Url.fromString single.navigate of
                                                Just url ->
                                                    [ admin.update 100 (Audio.userMsg (Types.UrlChanged url))
                                                    , admin.checkView 100
                                                        (Test.Html.Query.has
                                                            [ Test.Html.Selector.exactText "Hello admin 3!"
                                                            , Test.Html.Selector.exactText "Write a message to Sven"
                                                            ]
                                                        )
                                                    , -- There shouldn't be anything to navigate back to. Mobile PWAs should stay at the first entry in the navigation history
                                                      admin.navigateBack 100
                                                    , admin.checkView 100
                                                        (Test.Html.Query.has
                                                            [ Test.Html.Selector.exactText "Hello admin 3!"
                                                            , Test.Html.Selector.exactText "Write a message to Sven"
                                                            ]
                                                        )
                                                    ]

                                                Nothing ->
                                                    [ T.checkState 0 (\_ -> Err "Message notification has malformed url") ]

                                        _ ->
                                            [ T.checkState 0 (\_ -> Err "Should be only one new message notification") ]
                                )
                            ]
                        ]
                    )
                ]
            )
        ]


inviteUserAndDmChat : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
inviteUserAndDmChat config =
    E2EHelper.startTest
        "Invite user and then have DM chat"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , E2EHelper.writeMessage user 100 "Hello"
                        , admin.click 100 (Dom.id "guildsColumn_openDm_2")
                        , E2EHelper.writeMessage user 100 "Hello 2"
                        , E2EHelper.writeMessage admin 100 "Hello from *admin*"
                        , user.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Sven" ] html
                                    |> Test.Html.Query.count (Expect.equal 2)
                            )
                        , E2EHelper.createThread user (Id.fromInt 1)
                        , E2EHelper.writeMessage user 100 "Writing in thread"
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.find [ Test.Html.Selector.id "guild_threadStarterIndicator_1" ] html
                                    |> Test.Html.Query.has
                                        [ Test.Html.Selector.containing [ Test.Html.Selector.exactText "Sven" ]
                                        ]
                            )
                        , admin.click 100 (Dom.id "guild_threadStarterIndicator_1")
                        ]
                    )
                ]
            )
        ]


inactiveThreadsAreHiddenTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
inactiveThreadsAreHiddenTest config =
    T.start
        "Inactive threads are hidden"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ E2EHelper.writeMessage user 100 "Hello!"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , E2EHelper.writeMessage admin 100 "Hello from admin!"
                        , E2EHelper.createThread admin (Id.fromInt 0)
                        , E2EHelper.writeMessage admin 100 "Hello from admin in thread!"
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        ]
                    )
                ]
            )
        , T.connectFrontend
            (Duration.days 7.1 |> Duration.inMilliseconds)
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ T.andThen
                    10
                    (\data -> [ admin.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.navigateBack 100
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
                , E2EHelper.writeMessage admin 100 "Hello again from thread!"
                , admin.navigateBack 100
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                ]
            )
        ]
