module E2ESlack exposing (linkSlackLoadsChannelsTest, slackWebsocketBackoffTest, slackWebsocketTest, unlinkSlackTest, viewAndWriteInSlackTest)

import Array
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Time as Time
import Effect.Websocket as Websocket
import Id exposing (ChannelMessageId)
import IdArray
import Message exposing (Message(..))
import NonemptySet
import OneToOne
import Pages.Admin
import PersonName
import RichText
import SeqDict
import SeqSet
import Slack
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


messageToString : Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId) -> String
messageToString message =
    case message of
        UserTextMessage data ->
            Slack.idToString data.createdBy
                ++ ": "
                ++ RichText.toString
                    Time.utc
                    False
                    (SeqDict.fromList [ ( Slack.Id "U09DK3NCPMG", { name = PersonName.fromStringLossy "zig" } ) ])
                    (SeqDict.fromList [ ( ( Slack.Id "C09DJDQUKKN", Nothing ), { name = "social" } ) ])
                    data.content.content

        UserJoinedMessage _ userId _ _ ->
            Slack.idToString userId ++ " joined"

        EncryptedUserTextMessage _ ->
            "Encrypted"

        DeletedMessage _ ->
            "Deleted"

        CallStarted _ ->
            "Call"

        GameStarted _ ->
            "Game"


linkSlackLoadsChannelsTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
linkSlackLoadsChannelsTest config =
    E2EHelper.startTest
        "Linking Slack loads each workspace's channels, DMs, messages and users and the admin page lists them"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 1000 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_slackSection")
                , admin.input 100 (Dom.id "userOptions_slackCookie") E2EHelper.legitSlackCookie
                , admin.input
                    100
                    (Dom.id "userOptions_slackTeamsJson")
                    ("{\"T09DJDQL18U\":{\"token\":\""
                        ++ E2EHelper.legitSlackToken
                        ++ "\"},\"T0SECOND\":{\"token\":\""
                        ++ E2EHelper.secondSlackToken
                        ++ "\"},\"T0EXPIRED\":{\"token\":\"xoxc-expired-token\"}}"
                    )
                , admin.click 100 (Dom.id "userOptions_submitSlackData")
                , E2EHelper.hasExactText
                    admin
                    [ "Loaded test-slack", "Couldn't load a workspace: Slack said invalid_auth" ]
                , -- Each channel knows which linked Slack users got it back from users.conversations
                  -- and whether it's private.
                  T.checkBackend
                    100
                    (\backend ->
                        case
                            SeqDict.values (E2EHelper.unwrapBackend backend).slackWorkspaces
                                |> List.map
                                    (\workspace ->
                                        SeqDict.toList workspace.channels
                                            |> List.map
                                                (\( channelId, channel ) ->
                                                    Slack.idToString channelId
                                                        :: (if channel.isPrivate then
                                                                "private"

                                                            else
                                                                "public"
                                                           )
                                                        :: List.sort (List.map Slack.idToString (SeqSet.toList channel.linkedMembers))
                                                        |> String.join " "
                                                )
                                            |> List.sort
                                    )
                        of
                            [ [ "C09DJDQSWLU public U09DJDQL1A8 U09DK3NCPMG", "C09DJDQUKKN public U09DJDQL1A8", "C0C8993MS6N private U09DJDQL1A8", "C0SECRET123 private U09DK3NCPMG" ] ] ->
                                Ok ()

                            channels ->
                                Err
                                    ("Expected one workspace with every page of both users' channels, got "
                                        ++ String.join " | " (List.map (String.join ", ") channels)
                                    )
                    )
                , T.checkBackend
                    100
                    (\backend ->
                        case
                            SeqDict.toList (E2EHelper.unwrapBackend backend).slackDmChannels
                                |> List.map
                                    (\( channelId, dmChannel ) ->
                                        Slack.idToString channelId
                                            :: List.map Slack.idToString (NonemptySet.toList dmChannel.members)
                                            |> String.join " "
                                    )
                        of
                            [ "D09DK3P5RPC U09DJDQL1A8 U09DK3NCPMG", "D09DJDQMBPW U09DJDQL1A8", "C0AMPIM1234 U09DJDQL1A8 U09DK3NCPMG U0THIRD" ] ->
                                Ok ()

                            dmChannels ->
                                Err ("Expected the two DMs and the group DM with their members, got " ++ String.join " | " dmChannels)
                    )
                , T.checkBackend
                    100
                    (\backend ->
                        let
                            channelMessages : List String
                            channelMessages =
                                SeqDict.values (E2EHelper.unwrapBackend backend).slackWorkspaces
                                    |> List.filterMap (\workspace -> SeqDict.get (Slack.Id "C09DJDQSWLU") workspace.channels)
                                    |> List.concatMap (\channel -> IdArray.toList channel.messages)
                                    |> List.map messageToString
                        in
                        if
                            channelMessages
                                == [ "U09DJDQL1A8: Plain <old> message"
                                   , "U09DK3NCPMG joined"
                                   , "U09DJDQL1A8: 👋 Hello @zig see [at-chat](https://at-chat.app/) in #social *_now_*"
                                   , "U09DJDQL1A8: Run `make`\n```elm make src/Main.elm```"
                                   , "U09DK3NCPMG: Before\n> Quoted\n* First item\n* Second item"
                                   ]
                        then
                            Ok ()

                        else
                            Err ("Unexpected messages in #all-test-slack: " ++ String.join " | " channelMessages)
                    )
                , T.checkBackend
                    100
                    (\backend ->
                        case
                            SeqDict.values (E2EHelper.unwrapBackend backend).slackDmChannels
                                |> List.map (\dmChannel -> IdArray.toList dmChannel.messages |> List.map messageToString)
                        of
                            [ [ "U09DK3NCPMG: 🌞 Good a~~fternoon!~~" ], [], [] ] ->
                                Ok ()

                            dmMessages ->
                                Err ("Unexpected DM messages: " ++ String.join " | " (List.map (String.join ", ") dmMessages))
                    )
                , T.checkBackend
                    100
                    (\backend ->
                        case
                            SeqDict.toList (E2EHelper.unwrapBackend backend).slackUsers
                                |> List.map
                                    (\( slackUserId, slackUser ) ->
                                        Slack.idToString slackUserId
                                            ++ (case slackUser of
                                                    Types.SlackFullData _ ->
                                                        " linked"

                                                    Types.SlackBasicData _ ->
                                                        ""
                                               )
                                    )
                                |> List.sort
                        of
                            [ "U09DFEXKH9T", "U09DJDQL1A8 linked", "U09DK3NCPMG linked", "U0THIRD" ] ->
                                Ok ()

                            slackUsers ->
                                Err ("Unexpected Slack users: " ++ String.join ", " slackUsers)
                    )
                , admin.input
                    100
                    (Dom.id "userOptions_slackTeamsJson")
                    ("{\"T0SECOND\":{\"token\":\"" ++ E2EHelper.secondSlackTokenAfterLeaving ++ "\"}}")
                , admin.click 100 (Dom.id "userOptions_submitSlackData")
                , T.checkBackend
                    100
                    (\backend ->
                        let
                            linkedMembers : String -> List String
                            linkedMembers channelId =
                                SeqDict.values (E2EHelper.unwrapBackend backend).slackWorkspaces
                                    |> List.filterMap (\workspace -> SeqDict.get (Slack.Id channelId) workspace.channels)
                                    |> List.concatMap (\channel -> SeqSet.toList channel.linkedMembers)
                                    |> List.map Slack.idToString
                                    |> List.sort
                        in
                        case ( linkedMembers "C0SECRET123", linkedMembers "C09DJDQSWLU" ) of
                            ( [], [ "U09DJDQL1A8", "U09DK3NCPMG" ] ) ->
                                Ok ()

                            ( secret, allTestSlack ) ->
                                Err
                                    ("After ziggler left #secret it should be visible to no one and #all-test-slack still to both, got "
                                        ++ String.join ", " secret
                                        ++ " and "
                                        ++ String.join ", " allTestSlack
                                    )
                    )
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Pages.Admin.expandSectionButtonId Pages.Admin.SlackWorkspacesSection)
                , E2EHelper.hasExactText admin [ "test-slack", "Channels: 4", "Users: 4", "slack-admin", "ziggler" ]
                , E2EHelper.hasNotExactText admin [ "#social" ]
                , admin.click 100 (Pages.Admin.expandSlackWorkspaceButtonId (Slack.Id "T09DJDQL18U"))
                , E2EHelper.hasExactText admin [ "#all-test-slack", "#social", "#newer-channel", "#secret", "Private", "Visible to:", "Messages: 5" ]
                , admin.click 100 (Pages.Admin.expandSectionButtonId Pages.Admin.SlackDmChannelsSection)
                , E2EHelper.hasExactText admin [ "D09DK3P5RPC", "C0AMPIM1234", "third", "Messages: 1" ]
                , admin.click 100 (Pages.Admin.deleteSlackDmChannelButtonId (Slack.Id "C0AMPIM1234"))
                , E2EHelper.hasNotExactText admin [ "third" ]
                , T.checkBackend
                    100
                    (\backend ->
                        if SeqDict.size (E2EHelper.unwrapBackend backend).slackDmChannels == 2 then
                            Ok ()

                        else
                            Err "Deleting the group DM in the admin page should remove it from the backend"
                    )
                , admin.click 100 (Pages.Admin.deleteSlackWorkspaceButtonId (Slack.Id "T09DJDQL18U"))
                , E2EHelper.hasExactText admin [ "No Slack workspaces" ]
                , T.checkBackend
                    100
                    (\backend ->
                        if SeqDict.isEmpty (E2EHelper.unwrapBackend backend).slackWorkspaces then
                            Ok ()

                        else
                            Err "Deleting the workspace in the admin page should remove it from the backend"
                    )
                ]
            )
        ]


linkSlack : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
linkSlack user =
    T.group
        [ user.click 1000 (Dom.id "guild_showUserOptions")
        , user.click 100 (Dom.id "userOptions_slackSection")
        , user.input 100 (Dom.id "userOptions_slackCookie") E2EHelper.legitSlackCookie
        , user.input
            100
            (Dom.id "userOptions_slackTeamsJson")
            ("{\"T09DJDQL18U\":{\"token\":\"" ++ E2EHelper.legitSlackToken ++ "\"}}")
        , user.click 100 (Dom.id "userOptions_submitSlackData")
        , E2EHelper.hasExactText user [ "Loaded test-slack" ]
        ]


lastSlackMessage :
    E2EHelper.BackendModel2
    -> (Types.BackendModel -> Maybe { a | messages : IdArray.IdArray ChannelMessageId (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId)), linkedMessageIds : OneToOne.OneToOne (Slack.Id Slack.MessageId) (Id.Id ChannelMessageId) })
    -> Result String ( String, Bool )
lastSlackMessage backend getChannel =
    case getChannel (E2EHelper.unwrapBackend backend) of
        Just channel ->
            case List.reverse (IdArray.toList channel.messages) of
                last :: _ ->
                    Ok
                        ( messageToString last
                        , OneToOne.memberFirst (Slack.Id "1791638900.000100") channel.linkedMessageIds
                        )

                [] ->
                    Err "No messages"

        Nothing ->
            Err "Channel not found"


boolToString : Bool -> String
boolToString bool =
    if bool then
        "yes"

    else
        "no"


viewAndWriteInSlackTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
viewAndWriteInSlackTest config =
    E2EHelper.startTest
        "Slack workspace channels and DMs can be read and written in"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , linkSlack admin
                ]
            )
        , T.connectFrontend
            100
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
                , admin.click 100 (Dom.id "guild_slackFriendLabel_D09DK3P5RPC")
                , E2EHelper.hasExactText admin [ "This is the start of your conversation with zig" ]
                , -- The message is "Good a~~fternoon!~~" so its text is split by the strikethrough
                  admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "fternoon!" ])
                , E2EHelper.writeMessage admin 100 "Hello zig"
                , E2EHelper.hasExactText admin [ "Hello zig" ]
                , T.checkBackend
                    100
                    (\backend ->
                        case lastSlackMessage backend (\model -> SeqDict.get (Slack.Id "D09DK3P5RPC") model.slackDmChannels) of
                            Ok ( "U09DJDQL1A8: Hello zig", True ) ->
                                Ok ()

                            Ok ( text, hasTs ) ->
                                Err ("Expected the DM message to be stored with the ts Slack gave it, got " ++ text ++ " (has ts: " ++ boolToString hasTs ++ ")")

                            Err error ->
                                Err error
                    )
                , admin.click 100 (Dom.id "guild_openSlackWorkspace_T09DJDQL18U")
                , E2EHelper.hasExactText admin [ "test-slack", "all-test-slack", "social", "newer-channel", "This is the start of #all-test-slack", "Plain <old> message" ]
                , E2EHelper.writeMessage admin 100 "Hi from *at-chat*"
                , E2EHelper.hasExactText admin [ "Hi from " ]
                , T.checkBackend
                    100
                    (\backend ->
                        case
                            lastSlackMessage
                                backend
                                (\model ->
                                    SeqDict.get (Slack.Id "T09DJDQL18U") model.slackWorkspaces
                                        |> Maybe.andThen (\workspace -> SeqDict.get (Slack.Id "C09DJDQSWLU") workspace.channels)
                                )
                        of
                            Ok ( "U09DJDQL1A8: Hi from *at-chat*", True ) ->
                                Ok ()

                            Ok ( text, hasTs ) ->
                                Err ("Expected the channel message to be stored with the ts Slack gave it, got " ++ text ++ " (has ts: " ++ boolToString hasTs ++ ")")

                            Err error ->
                                Err error
                    )
                , admin.click 100 (Dom.id "guild_openSlackChannel_C09DJDQUKKN")
                , E2EHelper.hasExactText admin [ "This is the start of #social" ]
                ]
            )
        ]


slackMessageEvent : { user : String, ts : String, text : String } -> String
slackMessageEvent { user, ts, text } =
    """{"type":"message","channel":"C09DJDQSWLU","text":\""""
        ++ text
        ++ """","blocks":[{"type":"rich_text","block_id":"abc","elements":[{"type":"rich_text_section","elements":[{"type":"text","text":\""""
        ++ text
        ++ """"}]}]}],"user":\""""
        ++ user
        ++ """","team":"T09DJDQL18U","event_ts":\""""
        ++ ts
        ++ """","ts":\""""
        ++ ts
        ++ "\"}"


allTestSlackMessageCount : E2EHelper.BackendModel2 -> Int
allTestSlackMessageCount backend =
    SeqDict.get (Slack.Id "T09DJDQL18U") (E2EHelper.unwrapBackend backend).slackWorkspaces
        |> Maybe.andThen (\workspace -> SeqDict.get (Slack.Id "C09DJDQSWLU") workspace.channels)
        |> Maybe.map (\channel -> List.length (IdArray.toList channel.messages))
        |> Maybe.withDefault 0


slackWebsocketTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
slackWebsocketTest config =
    E2EHelper.startTest
        "Slack messages created, edited and deleted elsewhere show up live"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , linkSlack admin
                ]
            )
        , T.connectFrontend
            100
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
                , admin.click 100 (Dom.id "guild_openSlackWorkspace_T09DJDQL18U")
                , E2EHelper.hasExactText admin [ "This is the start of #all-test-slack" ]
                , E2EHelper.andThenWebsocket
                    100
                    (\connection _ ->
                        [ T.websocketSendString 100 connection "relay_ready"
                        , E2EHelper.andThenWebsocket
                            100
                            (\_ websocketState ->
                                [ T.checkState
                                    0
                                    (\_ ->
                                        case Array.toList websocketState.dataSent |> List.map .data of
                                            [ "relay_ready", handshake ] ->
                                                if
                                                    String.contains "\"url\":\"wss://wss-primary.slack.com/?token=xoxc-legit-token\"" handshake
                                                        && String.contains "[\"Cookie\",\"d=xoxd-legit-cookie\"]" handshake
                                                then
                                                    Ok ()

                                                else
                                                    Err ("Unexpected relay handshake: " ++ handshake)

                                            _ ->
                                                Err "Expected the backend to answer relay_ready with one message"
                                    )
                                ]
                            )
                        , T.websocketSendString 100 connection """{"type":"hello"}"""
                        , T.websocketSendString
                            100
                            connection
                            (slackMessageEvent { user = "U09DK3NCPMG", ts = "1791640000.000100", text = "Live from Slack" })
                        , E2EHelper.hasExactText admin [ "Live from Slack" ]
                        , T.websocketSendString
                            100
                            connection
                            """{"type":"message","subtype":"message_changed","channel":"C09DJDQSWLU","message":{"user":"U09DK3NCPMG","type":"message","edited":{"user":"U09DK3NCPMG","ts":"1791640010.000000"},"text":"Edited in Slack","blocks":[{"type":"rich_text","block_id":"abc","elements":[{"type":"rich_text_section","elements":[{"type":"text","text":"Edited in Slack"}]}]}],"ts":"1791640000.000100"},"event_ts":"1791640010.000200","ts":"1791640010.000200"}"""
                        , E2EHelper.hasExactText admin [ "Edited in Slack" ]
                        , T.websocketSendString
                            100
                            connection
                            """{"type":"message","subtype":"message_deleted","previous_message":{"user":"U09DK3NCPMG","type":"message","ts":"1791640000.000100","text":"Edited in Slack"},"channel":"C09DJDQSWLU","hidden":true,"deleted_ts":"1791640000.000100","event_ts":"1791640020.000400","ts":"1791640020.000400"}"""
                        , E2EHelper.hasNotExactText admin [ "Edited in Slack" ]
                        , E2EHelper.writeMessage admin 100 "Sent from at-chat"
                        , E2EHelper.hasExactText admin [ "Sent from at-chat" ]
                        , T.andThen
                            100
                            (\data ->
                                let
                                    countBefore : Int
                                    countBefore =
                                        allTestSlackMessageCount data.backend
                                in
                                [ -- Slack also sends at-chat's own messages back over the websocket
                                  T.websocketSendString
                                    100
                                    connection
                                    (slackMessageEvent { user = "U09DJDQL1A8", ts = "1791638900.000100", text = "Sent from at-chat" })
                                , T.checkBackend
                                    100
                                    (\backend ->
                                        if allTestSlackMessageCount backend == countBefore then
                                            Ok ()

                                        else
                                            Err "The echo of a message at-chat sent was added a second time"
                                    )
                                ]
                            )
                        ]
                    )
                , E2EHelper.checkNoErrorLogs
                ]
            )
        ]


adminSlackUserId : Slack.Id Slack.UserId
adminSlackUserId =
    Slack.Id "U09DJDQL1A8"


slackWebsocketBackoffTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
slackWebsocketBackoffTest config =
    E2EHelper.startTest
        "The Slack websocket reconnects with jittered exponential backoff"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , linkSlack admin

                -- The relay drops the connection four times without Slack ever saying hello, so the
                -- wait doubles each time: 0s, 1s, 3s, 7s (each shortened by up to half by the jitter).
                , slackDropAndReconnect 0
                , slackDropAndReconnect 1
                , slackDropAndReconnect 3
                , slackDropAndReconnect 7
                , E2EHelper.andThenWebsocket
                    100
                    (\connection _ -> [ T.websocketSendString 100 connection """{"type":"hello"}""" ])
                , -- Slack's hello means the connection works again, so the backoff starts over.
                  slackDropAndReconnect 0
                ]
            )
        ]


slackDropAndReconnect : Float -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
slackDropAndReconnect unjitteredDelay =
    T.group
        [ E2EHelper.andThenWebsocket
            100
            (\connection _ ->
                [ T.websocketClose 100 connection (Websocket.UnknownCode 4002) "Upstream failed"

                -- Check before any time passes, otherwise a delay of 0 has already run down.
                , T.checkBackend
                    0
                    (\backend ->
                        case SeqDict.get adminSlackUserId (E2EHelper.unwrapBackend backend).pendingSlackReconnects of
                            Just delay ->
                                if Duration.inSeconds delay >= unjitteredDelay / 2 && Duration.inSeconds delay <= unjitteredDelay then
                                    Ok ()

                                else
                                    Err
                                        ("Expected the Slack reconnect to be delayed by between "
                                            ++ String.fromFloat (unjitteredDelay / 2)
                                            ++ "s and "
                                            ++ String.fromFloat unjitteredDelay
                                            ++ "s, but it was "
                                            ++ String.fromFloat (Duration.inSeconds delay)
                                            ++ "s"
                                        )

                            Nothing ->
                                Err "Expected the backend to be waiting to reopen the Slack websocket"
                    )
                ]
            )
        , T.checkBackend
            (unjitteredDelay * 1000 + E2EHelper.gatewayReconnectDelay)
            (\backend ->
                case SeqDict.get adminSlackUserId (E2EHelper.unwrapBackend backend).slackUsers of
                    Just (Types.SlackFullData linkedUser) ->
                        case linkedUser.websocket of
                            Just _ ->
                                Ok ()

                            Nothing ->
                                Err "Expected the Slack websocket to be open again"

                    _ ->
                        Err "Expected the Slack user to still be linked"
            )
        ]


unlinkSlackTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
unlinkSlackTest config =
    E2EHelper.startTest
        "Unlinking a Slack account forgets its token and closes its websocket"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , linkSlack admin
                ]
            )
        , T.connectFrontend
            100
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
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_openSlackWorkspace_T09DJDQL18U" ])
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , E2EHelper.hasExactText admin [ "Slack Admin", "test-slack" ]
                , admin.click 100 (Dom.id "userOptions_unlinkSlack_U09DJDQL1A8")
                , E2EHelper.hasNotExactText admin [ "Slack Admin" ]
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_openSlackWorkspace_T09DJDQL18U" ])
                , T.checkState
                    100
                    (\data ->
                        let
                            backend : Types.BackendModel
                            backend =
                                E2EHelper.unwrapBackend data.backend
                        in
                        case SeqDict.get adminSlackUserId backend.slackUsers of
                            Just (Types.SlackBasicData _) ->
                                if
                                    List.any
                                        (\( ( requestedBy, _ ), websocketState ) ->
                                            requestedBy == T.RequestedByBackend && websocketState.closedAt == Nothing
                                        )
                                        (SeqDict.toList data.websockets)
                                then
                                    Err "Expected the Slack websocket to be closed"

                                else if SeqDict.isEmpty backend.pendingSlackReconnects then
                                    Ok ()

                                else
                                    Err "Expected no Slack reconnect to be pending"

                            _ ->
                                Err "Expected the Slack user to only have its basic data left"
                    )
                ]
            )
        ]
