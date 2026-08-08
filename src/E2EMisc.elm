module E2EMisc exposing
    ( channelSearchTest
    , codeBlockInputTest
    , dmThreadsTest
    , emojiSuggestionTest
    , exportChannelTest
    , exportDmChannelTest
    , friendsSearchTest
    , inactiveDmThreadsAreHiddenTest
    , inactiveThreadsAreHiddenTest
    , inviteUserAndDmChat
    , largePasteBecomesAttachment
    , mentionSuggestionTest
    , noTimestampSuggestionTest
    , profileImageOpensDm
    , timeOfDaySuggestionTest
    , timeOffsetSuggestionTest
    )

import Audio
import DmChannel
import DmChannelId
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Time as Time
import Expect
import FileStatus
import Html.Attributes
import Id
import Json.Encode
import List.Nonempty
import Local
import LocalState exposing (LocalState)
import Message
import Pages.Guild
import RichText
import Route
import SeqDict
import String.Nonempty
import Test.Html.Query
import Test.Html.Selector
import TimeInMinutes
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


{-| Writing a message counts as reading it, so the thread it went into holds nothing
unread for the person who wrote it.
-}
checkDmThreadIsRead : Id.Id Id.UserId -> Id.Id Id.ChannelMessageId -> FrontendModel -> Result String ()
checkDmThreadIsRead otherUserId threadMessageIndex model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState

                        newestMessageId : Maybe (Id.Id Id.ThreadMessageId)
                        newestMessageId =
                            SeqDict.get otherUserId local.dmChannels
                                |> Maybe.andThen (\dmChannel -> SeqDict.get threadMessageIndex dmChannel.threads)
                                |> Maybe.map DmChannel.latestFrontendThreadMessageId
                    in
                    if
                        SeqDict.get
                            ( Id.GuildOrDmId (Id.GuildOrDmId_Dm otherUserId), threadMessageIndex )
                            local.localUser.user.lastViewedThreads
                            == newestMessageId
                    then
                        Ok ()

                    else
                        Err "Expected the newest message in the DM thread to have been read"

                Types.NotLoggedIn _ ->
                    Err "Expected the frontend to be logged in"

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

                -- The admin wrote those two thread messages, so neither is unread for them
                , admin.checkModel 100 (checkDmThreadIsRead (Id.fromInt 2) (Id.fromInt 0))

                -- The thread is listed underneath the DM for both of them. The admin sees
                -- it under the user (id 2) and the user sees it under the admin (id 0).
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_0_0" ])

                -- Unread thread messages notify the user, who has read none of them
                , user.checkView 100 (Test.Html.Query.has [ threadNotification, dmNotification ])

                -- The unread overview names the DM after the person on the other end of
                -- it, and the thread after the message it hangs off
                , user.checkView
                    100
                    (\html ->
                        Test.Html.Query.find
                            [ Test.Html.Selector.id "guild_unreadOverviewOpenChannel_dm_0" ]
                            html
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Chat with", Test.Html.Selector.exactText "AT" ]
                    )
                , user.checkView
                    100
                    (\html ->
                        Test.Html.Query.find
                            [ Test.Html.Selector.id "guild_unreadOverviewOpenChannel_dm_0_thread_0" ]
                            html
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Chat with"
                                , Test.Html.Selector.exactText "AT"
                                , Test.Html.Selector.exactText "Hello in a DM!"
                                ]
                    )
                , user.snapshotView 100 { name = "User perspective" }
                , admin.snapshotView 100 { name = "Admin perspective" }

                -- Writing in the thread reaches the other user, and the thread's messages
                -- stay out of the DM itself
                , user.click 100 (Dom.id "guild_viewDmThread_0_0")
                , E2EHelper.hasExactText user [ "First message in the DM thread", "Second message in the DM thread" ]
                , E2EHelper.writeMessage user 100 "Reply from the user"
                , user.checkModel 100 (checkDmThreadIsRead (Id.fromInt 0) (Id.fromInt 0))
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


{-| Noon on the day `E2EHelper.startTime` falls on. The suggestions a timestamp dropdown makes
are relative to the time the test is running at, so starting at midday leaves room either side
of it for them to land on the same day and read as a time rather than a date.
-}
middayStartTime : Time.Posix
middayStartTime =
    Duration.addTo E2EHelper.startTime (Duration.hours 12)


{-| The minutes of every timestamp in the most recent message the backend has stored.
-}
lastMessageTimestamps : E2EHelper.BackendModel2 -> List Int
lastMessageTimestamps backend =
    case E2EHelper.lastGuildChannelMessage backend of
        Just ( _, _, Message.UserTextMessage data ) ->
            List.Nonempty.toList data.content
                |> List.filterMap
                    (\part ->
                        case part of
                            RichText.Timestamp time ->
                                TimeInMinutes.toSeconds time // 60 |> Just

                            _ ->
                                Nothing
                    )

        _ ->
            []


expectLastMessageTimestamps : List Int -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
expectLastMessageTimestamps expected data =
    if lastMessageTimestamps data.backend == expected then
        Ok ()

    else
        Err
            ("Expected the stored message to hold timestamps at "
                ++ String.join "," (List.map String.fromInt expected)
                ++ " minutes but it held "
                ++ String.join "," (List.map String.fromInt (lastMessageTimestamps data.backend))
            )


{-| Noon on the 15th of July 2026, read in `E2EHelper.testTimezone`, in minutes since the
epoch. The clocks are forward an hour by then, so it's 11:00 UTC.
-}
summerNoon : Int
summerNoon =
    29735220


{-| Noon on the 15th of December 2026, read in `E2EHelper.testTimezone`. The clocks have gone
back by then, so it's 12:00 UTC and an hour later in the day than `summerNoon` would suggest.
-}
winterNoon : Int
winterNoon =
    29955600


{-| Writing a time of day offers the times a clock shows it at, and the one that's picked is
still a timestamp by the time the backend has it.
-}
timeOfDaySuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
timeOfDaySuggestionTest config =
    E2EHelper.startTest
        "Writing a time of day suggests timestamps"
        middayStartTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId
                , admin.input 100 Pages.Guild.channelTextInputId "Meet at 18:00"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 13, end = 13 }
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Add a timestamp" ])

                -- Suggestions that land on another day read as a date, which is the same text
                -- that picking them writes into the message.
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "January 2, 1970 at 06:00" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "January 2, 1970 at 18:00" ])
                , admin.input 100 Pages.Guild.channelTextInputId "Meet at July 15, 2026 at 12:00"

                -- Enter picks a suggestion while the dropdown is open, so it has to be shut
                -- before the message can be sent. Writing out a whole timestamp shuts it,
                -- since the time of day on the end of one is already part of a timestamp.
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 30, end = 30 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , T.checkState 100 (expectLastMessageTimestamps [ summerNoon ])
                , admin.input 100 Pages.Guild.channelTextInputId "Meet at December 15, 2026 at 12:00"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 34, end = 34 }
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , T.checkState 100 (expectLastMessageTimestamps [ winterNoon ])
                ]
            )
        ]


{-| Writing a time offset suggests times either side of now, and the timestamp that ends up in
the message is still there after the message has been round tripped through an edit.
-}
timeOffsetSuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
timeOffsetSuggestionTest config =
    E2EHelper.startTest
        "Writing a time offset suggests a timestamp that survives being sent and edited"
        middayStartTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                let
                    withTimestamp : String
                    withTimestamp =
                        "Remind me in January 1, 1970 at 17:00"
                in
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId
                , admin.input 100 Pages.Guild.channelTextInputId "Remind me in 5 hours"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 20, end = 20 }
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Add a timestamp" ])

                -- Picking a suggestion closes the dropdown. What it writes into the message is
                -- put there by js, which these tests don't run, so the text it would have left
                -- behind is typed in its place.
                , admin.click 100 (Pages.Guild.dropdownButtonId 0)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])
                , admin.input 100 Pages.Guild.channelTextInputId withTimestamp
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , T.checkState 100 (expectLastMessageTimestamps [ 17 * 60 ])

                -- The message shows the moment rather than the words that were typed.
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "17:00" ])

                -- Editing turns the message back into text, which is where a timestamp that
                -- can't be read back would be lost.
                , E2EHelper.focusEvent admin 100 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.keyDown 100 Pages.Guild.channelTextInputId "ArrowUp" []
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "editMessageTextInput"
                        , Test.Html.Selector.attribute (Html.Attributes.value withTimestamp)
                        ]
                    )
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , T.checkState 100 (expectLastMessageTimestamps [ 17 * 60 ])
                ]
            )
        ]


{-| The dropdown stays out of the way of text that isn't asking for a timestamp, including the
time of day at the end of a timestamp that's already there.
-}
noTimestampSuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
noTimestampSuggestionTest config =
    E2EHelper.startTest
        "Text that isn't asking for a timestamp doesn't get one suggested"
        middayStartTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId
                , admin.input 100 Pages.Guild.channelTextInputId "see you later"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 13, end = 13 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])

                -- A unit needs a number in front of it to be an offset.
                , admin.input 100 Pages.Guild.channelTextInputId "later that day"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 14, end = 14 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])

                -- The 18:00 on the end of a timestamp is already part of one, so offering to
                -- turn it into another would nest a timestamp inside the one that's there.
                , admin.input 100 Pages.Guild.channelTextInputId "Meet at January 1, 1970 at 18:00"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 32, end = 32 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])

                -- Away from the end of the words it reads, there's nothing to replace.
                , admin.input 100 Pages.Guild.channelTextInputId "Remind me in 5 hours and also buy milk"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 38, end = 38 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])
                ]
            )
        ]


{-| How many people the most recent message the backend has stored mentions.
-}
lastMessageMentionCount : E2EHelper.BackendModel2 -> Int
lastMessageMentionCount backend =
    case E2EHelper.lastGuildChannelMessage backend of
        Just ( _, _, Message.UserTextMessage data ) ->
            List.Nonempty.toList data.content
                |> List.filter
                    (\part ->
                        case part of
                            RichText.UserMention _ ->
                                True

                            _ ->
                                False
                    )
                |> List.length

        _ ->
            0


{-| Writing an @ suggests the people who can be mentioned, and the one that's picked is a
mention rather than their name in text by the time the backend has it.
-}
mentionSuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
mentionSuggestionTest config =
    E2EHelper.startTest
        "Writing an @ suggests people to mention"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId

                -- Only the people in the guild whose name starts with what's been written so
                -- far, so the admin's own name isn't among them.
                , admin.input 100 Pages.Guild.channelTextInputId "Hey @S"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 6, end = 6 }
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Mention a user" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Stevie Steve" ])

                -- A name nobody in the guild has leaves nothing to suggest.
                , admin.input 100 Pages.Guild.channelTextInputId "Hey @Zz"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 7, end = 7 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Mention a user" ])

                -- Picking a suggestion closes the dropdown. The name it writes into the message
                -- is put there by js, which these tests don't run, so the text it would have
                -- left behind is typed in its place.
                , admin.input 100 Pages.Guild.channelTextInputId "Hey @S"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 6, end = 6 }
                , admin.click 100 (Pages.Guild.dropdownButtonId 0)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Mention a user" ])
                , admin.input 100 Pages.Guild.channelTextInputId "Hey @Stevie Steve"
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , T.checkState
                    100
                    (\data ->
                        if lastMessageMentionCount data.backend == 1 then
                            Ok ()

                        else
                            Err
                                ("Expected the stored message to mention one person but it mentioned "
                                    ++ String.fromInt (lastMessageMentionCount data.backend)
                                )
                    )
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "@Stevie Steve" ])
                ]
            )
        ]


{-| Writing a colon and enough of a name to narrow it down suggests emoji to add.
-}
emojiSuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
emojiSuggestionTest config =
    E2EHelper.startTest
        "Writing a colon suggests emoji"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId

                -- Two characters match too much of the emoji list to be worth showing.
                , admin.input 100 Pages.Guild.channelTextInputId "Party :ta"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 9, end = 9 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a sticker or emoji" ])
                , admin.input 100 Pages.Guild.channelTextInputId "Party :tada"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 11, end = 11 }
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Add a sticker or emoji" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText ":tada:" ])

                -- Picking a suggestion closes the dropdown. As with a mention, what it writes
                -- into the message is put there by js, so the emoji it would have left behind
                -- is typed in its place.
                , admin.click 100 (Pages.Guild.dropdownButtonId 0)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a sticker or emoji" ])
                , admin.input 100 Pages.Guild.channelTextInputId "Party 🎉"
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "🎉" ])
                ]
            )
        ]


{-| Checks what's been written into the channel message input so far.
-}
checkDraft : Maybe String -> FrontendModel -> Result String ()
checkDraft expected model =
    let
        draft : Maybe String
        draft =
            case Audio.userModel model of
                Types.Loaded loaded ->
                    case loaded.loginStatus of
                        Types.LoggedIn loggedIn ->
                            SeqDict.values loggedIn.drafts
                                |> List.head
                                |> Maybe.map String.Nonempty.toString

                        Types.NotLoggedIn _ ->
                            Nothing

                Types.Loading _ ->
                    Nothing
    in
    if draft == expected then
        Ok ()

    else
        Err
            ("Expected the message input to contain "
                ++ Maybe.withDefault "nothing" expected
                ++ " but it contained "
                ++ Maybe.withDefault "nothing" draft
            )


{-| While the cursor is inside a \`\`\` code block, enter writes a line break instead of sending the
message and tab writes two spaces instead of moving the focus.
-}
codeBlockInputTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
codeBlockInputTest config =
    E2EHelper.startTest
        "Enter and tab behave differently inside a code block"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId

                -- The code block hasn't been closed yet so enter is left to the textarea to
                -- handle (which writes a line break) rather than sending the message.
                , admin.input 100 Pages.Guild.channelTextInputId "```"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 3, end = 3 }
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , admin.checkModel 100 (checkDraft (Just "```"))

                -- Tab writes two spaces. Normally js is what puts them in the text input but
                -- these tests don't run js, so only the model is checked here.
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Tab" []
                , admin.checkModel 100 (checkDraft (Just "```  "))

                -- Once the code block is closed, the cursor is outside of it again and enter
                -- sends the message.
                , admin.input 100 Pages.Guild.channelTextInputId "```\nlet x = 1\n```"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 17, end = 17 }
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , admin.checkModel 100 (checkDraft Nothing)
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "let x = 1" ])

                -- Tab is only special inside a code block. Everywhere else it's left alone so
                -- that it still moves the focus.
                , admin.input 100 Pages.Guild.channelTextInputId "no code block"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 13, end = 13 }
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Tab" []
                , admin.checkModel 100 (checkDraft (Just "no code block"))
                ]
            )
        ]
