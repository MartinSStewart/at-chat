module E2EMisc exposing
    ( channelSearchTest
    , dmThreadsTest
    , exportChannelTest
    , exportDmChannelTest
    , friendsSearchTest
    , inactiveDmThreadsAreHiddenTest
    , inactiveThreadsAreHiddenTest
    , inviteUserAndDmChat
    , largePasteBecomesAttachment
    , profileImageOpensDm
    )

import Audio
import DmChannelId
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Expect
import FileStatus
import Html.Attributes
import Id
import Json.Encode
import Local
import Message
import Pages.Guild
import Route
import SeqDict
import String.Nonempty
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


{-| Pasting a large chunk of text that would push the message over the max message length converts the pasted text into a text file attachment instead of inserting it into the text input.
-}
largePasteBecomesAttachment :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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


{-| Pressing "Export channel" in the member column asks the backend for a JSON
copy of the channel and downloads it. The JSON should contain every message plus
the publicly available data of everyone with access to the channel.
-}
exportChannelTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
exportChannelTest config =
    E2EHelper.startTest
        "Export a guild channel to a JSON file"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.writeMessage admin 1000 "Hello everyone"
                , admin.click 1000 (Dom.id "guild_showMembers")
                , admin.click 1000 (Dom.id "guild_exportChannel")
                , T.checkState
                    1000
                    (\data ->
                        case data.downloads of
                            [ download ] ->
                                case download.content of
                                    T.StringFile content ->
                                        case
                                            List.filter
                                                (\text -> not (String.contains text content))
                                                [ "Hello everyone", "\"AT\"", "Stevie Steve" ]
                                        of
                                            [] ->
                                                -- None of these messages were replied to, edited,
                                                -- reacted to or given files, so those fields should
                                                -- be left out instead of exported as nulls and
                                                -- empty lists.
                                                case
                                                    List.filter
                                                        (\text -> String.contains text content)
                                                        [ "\"editedAt\""
                                                        , "\"repliedTo\""
                                                        , "\"reactions\""
                                                        , "\"attachedFiles\""
                                                        , "\"embeds\""
                                                        ]
                                                of
                                                    [] ->
                                                        Ok ()

                                                    empty ->
                                                        Err
                                                            ("Empty fields in the exported JSON: "
                                                                ++ String.join ", " empty
                                                            )

                                            missing ->
                                                Err ("Missing from the exported JSON: " ++ String.join ", " missing)

                                    T.BytesFile _ ->
                                        Err "The exported channel should be a text file"

                            downloads ->
                                Err
                                    ("Expected a single download, instead got "
                                        ++ String.fromInt (List.length downloads)
                                    )
                    )
                ]
            )
        ]


{-| DM channels have a member column too, listing the two people in the DM and
the same "Export channel" button that guild channels have.
-}
exportDmChannelTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
exportDmChannelTest config =
    E2EHelper.startTest
        "Export a DM channel to a JSON file"
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
                        [ E2EHelper.openDm user 1000 "0"
                        , E2EHelper.writeMessage user 100 "Hello in a DM"
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Members (2)" ])
                        , user.click 100 (Dom.id "guild_showMembers")
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Members (2)" ])
                        , user.click 1000 (Dom.id "guild_exportChannel")
                        , T.checkState
                            1000
                            (\data ->
                                case data.downloads of
                                    [ download ] ->
                                        case download.content of
                                            T.StringFile content ->
                                                case
                                                    List.filter
                                                        (\text -> not (String.contains text content))
                                                        [ "Hello in a DM", "\"AT\"", "\"Sven\"" ]
                                                of
                                                    [] ->
                                                        Ok ()

                                                    missing ->
                                                        Err ("Missing from the exported JSON: " ++ String.join ", " missing)

                                            T.BytesFile _ ->
                                                Err "The exported channel should be a text file"

                                    downloads ->
                                        Err
                                            ("Expected a single download, instead got "
                                                ++ String.fromInt (List.length downloads)
                                            )
                            )
                        ]
                    )
                ]
            )
        ]


{-| Simulates the browser moving focus into a search input. Unlike
`E2EHelper.focusEvent` this includes the `selectionDirection` field, which the
focus decoder requires before it will record the input as focused.
-}
focusSearchInput :
    Dom.HtmlId
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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


friendsSearchTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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
                        [ E2EHelper.openDm user 1000 "0"
                        , E2EHelper.writeMessage user 100 "Hello admin!"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , E2EHelper.openDm admin 100 "2"

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


channelSearchTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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

                -- The search row only appears for guilds with more than 6 channels.
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

                -- With 7 channels the search row appears below the header.
                , admin.checkView 100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id (Dom.idToString Pages.Guild.channelSearchInputId)
                        , Test.Html.Selector.attribute (Html.Attributes.placeholder "Search channels")
                        ]
                    )
                , admin.snapshotView 100 { name = "Channel search row in channel column" }
                , admin.input 100 Pages.Guild.channelSearchInputId "zeta"
                , admin.checkView 100
                    (Test.Html.Query.has [ Test.Html.Selector.id "guild_openChannel_6" ])
                , admin.checkView 100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_openChannel_0" ])
                , admin.snapshotView 100 { name = "Channel search row filters channel column" }
                , admin.input 100 Pages.Guild.channelSearchInputId "does not match any channel"
                , admin.checkView 100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_openChannel_6" ])
                , admin.checkView 100
                    (Test.Html.Query.has [ Test.Html.Selector.exactText "No matching channels\u{00A0}found" ])

                -- Clearing the text shows all channels again.
                , admin.click 100 (Dom.id "guild_clearChannelSearch")
                , admin.checkView 100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "guild_openChannel_0"
                        , Test.Html.Selector.id "guild_openChannel_6"
                        , Test.Html.Selector.attribute (Html.Attributes.placeholder "Search channels")
                        ]
                    )
                ]
            )
        ]


inviteUserAndDmChat : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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
                        [ E2EHelper.openDm user 1000 "0"
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


{-| Clicking the profile image next to a message in a guild channel opens the DM channel
with whoever wrote it.
-}
profileImageOpensDm : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
profileImageOpensDm config =
    E2EHelper.startTest
        "Clicking a profile image opens the DM channel with that user"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.writeMessage user 100 "Click on my profile image!"
                , T.andThen
                    100
                    (\data ->
                        case E2EHelper.lastGuildChannelMessage data.backend of
                            Just ( _, messageId, Message.UserTextMessage message ) ->
                                [ admin.click 100 (Pages.Guild.profileImageButtonId messageId)
                                , admin.checkModel 100 (checkDmRouteWithUser message.createdBy)
                                ]

                            _ ->
                                [ admin.checkModel
                                    100
                                    (\_ -> Err "Expected the guild channel to contain the other user's message")
                                ]
                    )
                ]
            )
        ]


checkDmThreadRoute : Id.Id Id.ChannelMessageId -> FrontendModel -> Result String ()
checkDmThreadRoute threadMessageIndex model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case loaded.route of
                Route.DmRoute dmRoute ->
                    case dmRoute.threadRoute of
                        Route.ViewThreadWithFriends index _ _ ->
                            if index == threadMessageIndex then
                                Ok ()

                            else
                                Err "The DM thread route points at the wrong message"

                        Route.NoThreadWithFriends _ _ ->
                            Err "Expected the DM route to be viewing a thread"

                _ ->
                    Err "Expected to be viewing a DM channel"

        Types.Loading _ ->
            Err "Expected the frontend to have finished loading"


checkDmRouteWithUser : Id.Id Id.UserId -> FrontendModel -> Result String ()
checkDmRouteWithUser otherUserId model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case ( loaded.loginStatus, loaded.route ) of
                ( Types.LoggedIn loggedIn, Route.DmRoute dmRoute ) ->
                    let
                        currentUserId : Id.Id Id.UserId
                        currentUserId =
                            (Local.model loggedIn.localState).localUser.session.userId
                    in
                    if DmChannelId.otherUserId currentUserId dmRoute.channelId == Just otherUserId then
                        Ok ()

                    else
                        Err "Opened a DM channel with the wrong user"

                ( Types.LoggedIn _, _ ) ->
                    Err "Expected to be viewing a DM channel"

                ( Types.NotLoggedIn _, _ ) ->
                    Err "Expected the frontend to be logged in"

        Types.Loading _ ->
            Err "Expected the frontend to have finished loading"


inactiveThreadsAreHiddenTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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


{-| DM threads carry their own route, are listed underneath the DM in the friends
column and notify with the red count that every unread DM message gets.
-}
dmThreadsTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
dmThreadsTest config =
    E2EHelper.startTest
        "DM threads"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                let
                    -- The DM holds one unread message and the thread inside it two, so the
                    -- two notification counts can be told apart. The DM's own icon counts
                    -- both, which makes three.
                    threadNotification : Test.Html.Selector.Selector
                    threadNotification =
                        Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "2")

                    dmNotification : Test.Html.Selector.Selector
                    dmNotification =
                        Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "3")
                in
                [ -- The user waits on the friends page while the admin writes to them
                  user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.openDm admin 100 "2"
                , E2EHelper.writeMessage admin 100 "Hello in a DM!"
                , E2EHelper.createThread admin (Id.fromInt 0)
                , E2EHelper.writeMessage admin 100 "First message in the DM thread"
                , E2EHelper.writeMessage admin 100 "Second message in the DM thread"

                -- Opening a thread from a DM message puts the thread in the route
                , admin.checkModel 100 (checkDmThreadRoute (Id.fromInt 0))

                -- The thread is listed underneath the DM for both of them. The admin sees
                -- it under the user (id 2) and the user sees it under the admin (id 0).
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_0_0" ])

                -- Unread thread messages notify the user, who has read none of them
                , user.checkView 100 (Test.Html.Query.has [ threadNotification, dmNotification ])
                , user.snapshotView 100 { name = "User perspective" }
                , admin.snapshotView 100 { name = "Admin perspective" }

                -- Writing in the thread reaches the other user, and the thread's messages
                -- stay out of the DM itself
                , user.click 100 (Dom.id "guild_viewDmThread_0_0")
                , E2EHelper.hasExactText user [ "First message in the DM thread", "Second message in the DM thread" ]
                , E2EHelper.writeMessage user 100 "Reply from the user"
                , E2EHelper.hasExactText admin [ "Reply from the user" ]
                , user.click 100 (Dom.id "guild_friendLabel_0")
                , E2EHelper.hasExactText user [ "Hello in a DM!" ]
                , E2EHelper.hasNotExactText user [ "First message in the DM thread", "Reply from the user" ]

                -- Reading the thread took its notification away. The DM's own message is
                -- still unread until the DM itself is opened, so its icon drops from three
                -- to one instead of disappearing.
                , user.checkView 100 (Test.Html.Query.hasNot [ threadNotification, dmNotification ])

                -- The thread is stored on the backend, so loading its url from scratch
                -- shows the messages and lists the thread under the DM again
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    (Route.encode
                        (Route.DmRoute
                            { channelId = DmChannelId.fromUserIds (Id.fromInt 0) (Id.fromInt 2)
                            , threadRoute = Route.ViewThreadWithFriends (Id.fromInt 0) Nothing Route.HideMembersTab
                            , tab = Nothing
                            }
                        )
                    )
                    E2EHelper.desktopWindow
                    (\userReload ->
                        [ T.andThen
                            10
                            (\data ->
                                [ userReload.portEvent
                                    10
                                    "load_startup_data_from_js"
                                    (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                                ]
                            )
                        , E2EHelper.hasExactText
                            userReload
                            [ "First message in the DM thread", "Reply from the user" ]
                        , userReload.checkView
                            2000
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_0_0" ])
                        ]
                    )
                ]
            )
        ]


{-| Just like a guild channel's threads, a DM thread drops out of the friends
column once it's been quiet for a week, and comes back as soon as it's opened
again.
-}
inactiveDmThreadsAreHiddenTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
inactiveDmThreadsAreHiddenTest config =
    E2EHelper.startTest
        "Inactive DM threads are hidden"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.openDm admin 100 "2"
                , E2EHelper.writeMessage admin 100 "Hello in a DM!"
                , E2EHelper.createThread admin (Id.fromInt 0)
                , E2EHelper.writeMessage admin 100 "Hello in the thread!"
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])
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
                    (\data ->
                        [ admin.portEvent
                            10
                            "load_startup_data_from_js"
                            (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                        ]
                    )

                -- A week without a message and nothing unread in it, so the thread is gone
                -- from the column
                , admin.checkView
                    2000
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])

                -- Opening it from the DM message it hangs off puts it back
                , admin.click 100 (Dom.id "guild_friendLabel_2")
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])
                , E2EHelper.hasExactText admin [ "Hello in the thread!" ]
                , admin.snapshotView 100 { name = "Inactive threads are hidden" }
                ]
            )
        ]
