module E2EMisc exposing
    ( channelSearchTest
    , friendsSearchTest
    , inactiveThreadsAreHiddenTest
    , inviteUserAndDmChat
    , largePasteBecomesAttachment
    )

import Audio
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Expect
import FileStatus
import Html.Attributes
import Id
import Json.Encode
import Pages.Guild
import SeqDict
import String.Nonempty
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


{-| Pasting a large chunk of text that would push the message over the max message length converts the pasted text into a text file attachment instead of inserting it into the text input.
-}
largePasteBecomesAttachment :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
largePasteBecomesAttachment config =
    E2EHelper.startTest
        "Pasted text too long to fit in a message is attached as a text file instead"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                let
                    pastedText : String
                    pastedText =
                        String.repeat 250 "0123456789"
                in
                [ E2EHelper.focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.click 100 (Dom.id "channel_textinput")
                , admin.input 100 (Dom.id "channel_textinput") "Check this out! "
                , admin.input 100 (Dom.id "channel_textinput") ("Check this out! " ++ pastedText)

                -- The pasted text is removed from the draft and replaced with an attached file placeholder
                , T.checkState
                    100
                    (\data ->
                        case SeqDict.get admin.clientId data.frontends |> Maybe.map Audio.userModel of
                            Just (Types.Loaded loaded) ->
                                case loaded.loginStatus of
                                    Types.LoggedIn loggedIn ->
                                        if
                                            List.map
                                                String.Nonempty.toString
                                                (SeqDict.values loggedIn.drafts)
                                                == [ "Check this out! [!1]" ]
                                        then
                                            Ok ()

                                        else
                                            Err "The pasted text should have been replaced with a file attachment placeholder in the draft"

                                    Types.NotLoggedIn _ ->
                                        Err "Expected admin to be logged in"

                            _ ->
                                Err "Expected admin frontend to be loaded"
                    )

                -- The Rust server tells the backend about the uploaded file (in tests the
                -- upload HTTP response is mocked so this notification is injected manually,
                -- like E2EHelper.uploadNonImageAttachment does).
                , T.backendUpdate
                    100
                    (Types.GotRustServerFileUpload (FileStatus.fileHash "123123123") 2500 Nothing)
                , admin.keyDown 1000 (Dom.id "channel_textinput") "Enter" []
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "guild_message_1" ]
                    )
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.text "message.txt" ])
                ]
            )
        ]


{-| Simulates the browser moving focus into a search input. Unlike
`E2EHelper.focusEvent` this includes the `selectionDirection` field, which the
focus decoder requires before it will record the input as focused.
-}
focusSearchInput :
    Dom.HtmlId
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
focusSearchInput htmlId client =
    client.portEvent
        100
        "focus_changed_from_js"
        (Json.Encode.object
            [ ( "id", Json.Encode.string (Dom.idToString htmlId) )
            , ( "selectionStart", Json.Encode.int 0 )
            , ( "selectionEnd", Json.Encode.int 0 )
            , ( "selectionDirection", Json.Encode.string "forward" )
            ]
        )


friendsSearchTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
friendsSearchTest config =
    E2EHelper.startTest
        "Filter friends with the direct messages search input"
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
                        , E2EHelper.writeMessage user 100 "Hello admin!"
                        , admin.click 100 (Dom.id "guild_openDm_2")

                        -- The search input is transparent until it gets focus, so its placeholder
                        -- text is used to detect whether it is shown or not.
                        , admin.checkView 100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.id "guild_friendLabel_0"
                                , Test.Html.Selector.id "guild_friendLabel_2"
                                , Test.Html.Selector.exactText "Direct messages"
                                ]
                            )
                        , admin.checkView 100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter friends") ]
                            )
                        , focusSearchInput Pages.Guild.friendsSearchInputId admin
                        , admin.checkView 100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter friends") ]
                            )
                        , admin.snapshotView 100 { name = "Friends search input open" }
                        , admin.input 100 Pages.Guild.friendsSearchInputId "sven"
                        , admin.checkView 100
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_friendLabel_2" ])
                        , admin.checkView 100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_friendLabel_0" ])
                        , admin.snapshotView 100 { name = "Friends search input filters friends column" }
                        , admin.input 100 Pages.Guild.friendsSearchInputId "does not match anyone"
                        , admin.checkView 100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_friendLabel_2" ])

                        -- Clearing the text shows all friends again, and the input stays visible
                        -- because it still has focus.
                        , admin.click 100 (Dom.id "guild_clearFriendsSearch")
                        , admin.checkView 100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.id "guild_friendLabel_0"
                                , Test.Html.Selector.id "guild_friendLabel_2"
                                , Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter friends")
                                ]
                            )

                        -- Once the empty input loses focus it becomes transparent again.
                        , E2EHelper.focusEvent admin 100 Nothing Nothing
                        , admin.checkView 100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter friends") ]
                            )
                        ]
                    )
                ]
            )
        ]


channelSearchTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
channelSearchTest config =
    E2EHelper.startTest
        "Filter channels with the channel column search input"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 100 (Dom.id "guild_createGuild")
                , admin.input 100 (Dom.id "newGuildName") "My new guild!"
                , admin.click 100 (Dom.id "guild_createGuildSubmit")

                -- The search input only appears for guilds with more than 6 channels.
                , admin.checkView 100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.id (Dom.idToString Pages.Guild.channelSearchInputId) ]
                    )
                , List.map
                    (\channelName ->
                        T.group
                            [ admin.click 100 (Dom.id "guild_newChannel")
                            , admin.input 100 (Dom.id "newChannelName") channelName
                            , admin.click 100 (Dom.id "guild_createChannel")
                            ]
                    )
                    [ "alpha", "beta", "gamma", "delta", "epsilon", "zeta" ]
                    |> T.group

                -- With 7 channels the search input exists, but it is transparent until it gets
                -- focus, so its placeholder text is used to detect whether it is shown or not.
                , admin.checkView 100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id (Dom.idToString Pages.Guild.channelSearchInputId) ]
                    )
                , admin.checkView 100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter channels") ]
                    )
                , focusSearchInput Pages.Guild.channelSearchInputId admin
                , admin.checkView 100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter channels") ]
                    )
                , admin.snapshotView 100 { name = "Channel search input open" }
                , admin.input 100 Pages.Guild.channelSearchInputId "zeta"
                , admin.checkView 100
                    (Test.Html.Query.has [ Test.Html.Selector.id "guild_openChannel_6" ])
                , admin.checkView 100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_openChannel_0" ])
                , admin.snapshotView 100 { name = "Channel search input filters channel column" }
                , admin.input 100 Pages.Guild.channelSearchInputId "does not match any channel"
                , admin.checkView 100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_openChannel_6" ])
                , admin.checkView 100
                    (Test.Html.Query.has [ Test.Html.Selector.exactText "No matching channels found" ])

                -- Clearing the text shows all channels again, and the input stays visible
                -- because it still has focus.
                , admin.click 100 (Dom.id "guild_clearChannelSearch")
                , admin.checkView 100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "guild_openChannel_0"
                        , Test.Html.Selector.id "guild_openChannel_6"
                        , Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter channels")
                        ]
                    )

                -- Once the empty input loses focus it becomes transparent again.
                , E2EHelper.focusEvent admin 100 Nothing Nothing
                , admin.checkView 100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter channels") ]
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
