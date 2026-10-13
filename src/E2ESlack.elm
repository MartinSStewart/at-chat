module E2ESlack exposing (linkSlackLoadsChannelsTest, orphanedSlackWorkspacesTest, slackReactionsAndNewThreadTest, slackThreadsTest, slackUnreadAndNotificationsTest, slackWebsocketBackoffTest, slackWebsocketTest, unlinkSlackTest, viewAndWriteInSlackTest)

import Array
import Audio
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Time as Time
import Effect.Websocket as Websocket
import Emoji
import Expect
import Html.Attributes
import Id exposing (ChannelMessageId)
import IdArray
import Json.Decode
import Json.Encode
import Message exposing (Message(..))
import NonemptyDict
import NonemptySet
import OneOrGreater
import OneToOne
import Pages.Admin
import PersonName
import RichText
import SeqDict
import SeqSet
import Slack
import SlackEmoji
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
                            -- Only users found in the loaded conversations, so not the deleted bot U09DFEXKH9T
                            [ "U09DJDQL1A8 linked", "U09DK3NCPMG linked", "U0THIRD" ] ->
                                Ok ()

                            slackUsers ->
                                Err ("Unexpected Slack users: " ++ String.join ", " slackUsers)
                    )
                , T.checkState
                    100
                    (\data ->
                        let
                            urls : List String
                            urls =
                                List.filterMap (\request -> E2EHelper.decodeCustomRequest request |> Maybe.map .url) data.httpRequests
                        in
                        if List.any (String.endsWith "users.list") urls then
                            Err "Linking shouldn't load every user in the workspace"

                        else if List.member "https://edgeapi.slack.com/cache/T09DJDQL18U/users/info" urls then
                            Ok ()

                        else
                            Err "Expected the users to be loaded in a batch"
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
                , E2EHelper.hasExactText admin [ "test-slack", "Channels: 4", "Users: 3", "slack-admin", "ziggler" ]
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
                        , T.websocketSendString
                            100
                            connection
                            (slackMessageEvent { user = "U0NEWCOMER", ts = "1791640030.000100", text = "First post" })
                        , T.websocketSendString
                            100
                            connection
                            (slackMessageEvent { user = "U0NEWCOMER", ts = "1791640031.000100", text = "Second post" })
                        , E2EHelper.hasExactText admin [ "New Comer", "First post", "Second post" ]
                        , T.checkState
                            100
                            (\data ->
                                let
                                    lookups : List E2EHelper.CustomRequest
                                    lookups =
                                        List.filterMap E2EHelper.decodeCustomRequest data.httpRequests
                                            |> List.filter (\request -> String.endsWith "users.info" request.url)
                                in
                                if List.length lookups /= 1 then
                                    Err ("Expected the new Slack user to be looked up once, got " ++ String.fromInt (List.length lookups))

                                else if SeqDict.member (Slack.Id "U0NEWCOMER") (E2EHelper.unwrapBackend data.backend).slackUsers then
                                    Ok ()

                                else
                                    Err "Expected the new Slack user to be stored"
                            )
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


slackMentionEvent : { channel : String, user : String, ts : String, mentions : String } -> String
slackMentionEvent { channel, user, ts, mentions } =
    """{"type":"message","channel":\""""
        ++ channel
        ++ """","text":"<@"""
        ++ mentions
        ++ """> look","blocks":[{"type":"rich_text","block_id":"abc","elements":[{"type":"rich_text_section","elements":[{"type":"user","user_id":\""""
        ++ mentions
        ++ """"},{"type":"text","text":" look"}]}]}],"user":\""""
        ++ user
        ++ """","team":"T09DJDQL18U","event_ts":\""""
        ++ ts
        ++ """","ts":\""""
        ++ ts
        ++ "\"}"


slackDmEvent : { user : String, ts : String, text : String } -> String
slackDmEvent { user, ts, text } =
    """{"type":"message","channel":"D09DK3P5RPC","text":\""""
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


hasNotificationCount :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> String
    -> Maybe String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
hasNotificationCount user htmlId maybeCount =
    user.checkView
        100
        (\html ->
            case maybeCount of
                Just count ->
                    Test.Html.Query.find [ Test.Html.Selector.id htmlId ] html
                        |> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" count) ]

                Nothing ->
                    Test.Html.Query.find [ Test.Html.Selector.id htmlId ] html
                        |> Test.Html.Query.hasNot [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "1") ]
        )


shownNotificationUrls : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.Data FrontendModel E2EHelper.BackendModel2 -> List String
shownNotificationUrls user data =
    List.filterMap
        (\request ->
            if request.clientId == user.clientId && request.portName == "show_notification" then
                Json.Decode.decodeValue (Json.Decode.field "url" Json.Decode.string) request.value |> Result.toMaybe

            else
                Nothing
        )
        data.portRequests


adminSlackMentionCount : E2EHelper.BackendModel2 -> Int
adminSlackMentionCount backend =
    case NonemptyDict.get E2EHelper.defaultAdminId (E2EHelper.unwrapBackend backend).users of
        Just user ->
            SeqDict.values user.slackDirectMentions
                |> List.concatMap (\dict -> NonemptyDict.toList dict |> List.map Tuple.second)
                |> List.map OneOrGreater.toInt
                |> List.sum

        Nothing ->
            0


slackUnreadAndNotificationsTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
slackUnreadAndNotificationsTest config =
    E2EHelper.startTest
        "Slack messages show unread counts, and mentions and DMs notify"
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
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.keyUp 100 (Dom.id "userOptions_notificationMode") "ArrowDown" []
                , admin.click 100 (Dom.id "userOptions_closeUserOptions")
                , admin.portEvent 100 "check_notification_permission_from_js" (Json.Encode.string "granted")
                , admin.portEvent 100 "window_has_focus_from_js" (Json.Encode.bool False)
                , admin.click 100 (Dom.id "guild_openSlackWorkspace_T09DJDQL18U")
                , admin.click 100 (Dom.id "guild_openSlackChannel_C09DJDQUKKN")
                , E2EHelper.hasExactText admin [ "This is the start of #social" ]
                , -- Everything loaded when the account was linked starts out read.
                  hasNotificationCount admin "guild_openSlackChannel_C09DJDQSWLU" Nothing
                , hasNotificationCount admin "guildsColumn_openSlackDm_D09DK3P5RPC" Nothing
                , E2EHelper.andThenWebsocket
                    100
                    (\connection _ ->
                        [ T.websocketSendString 100 connection "relay_ready"
                        , T.websocketSendString 100 connection """{"type":"hello"}"""
                        , T.websocketSendString
                            100
                            connection
                            (slackMessageEvent { user = "U09DK3NCPMG", ts = "1791640000.000100", text = "Not for you" })
                        , hasNotificationCount admin "guild_openSlackChannel_C09DJDQSWLU" (Just "1")
                        , T.checkState
                            100
                            (\data ->
                                if List.isEmpty (shownNotificationUrls admin data) then
                                    Ok ()

                                else
                                    Err "A channel message that doesn't mention anyone shouldn't notify"
                            )
                        , T.websocketSendString
                            100
                            connection
                            (slackMentionEvent { channel = "C09DJDQSWLU", user = "U09DK3NCPMG", ts = "1791640001.000100", mentions = "U09DJDQL1A8" })
                        , T.websocketSendString
                            100
                            connection
                            (slackDmEvent { user = "U09DK3NCPMG", ts = "1791640002.000100", text = "Psst" })
                        , hasNotificationCount admin "guild_openSlackChannel_C09DJDQSWLU" (Just "1")
                        , hasNotificationCount admin "guildsColumn_openSlackDm_D09DK3P5RPC" (Just "1")
                        , T.checkState
                            100
                            (\data ->
                                if adminSlackMentionCount data.backend /= 1 then
                                    Err "Expected the mention to be counted"

                                else
                                    case List.sort (shownNotificationUrls admin data) of
                                        [ dmUrl, mentionUrl ] ->
                                            if
                                                String.endsWith "/sd/U09DJDQL1A8/D09DK3P5RPC" dmUrl
                                                    && String.endsWith "/sw/U09DJDQL1A8/T09DJDQL18U/c/C09DJDQSWLU" mentionUrl
                                            then
                                                Ok ()

                                            else
                                                Err ("Notifications open the wrong conversations: " ++ mentionUrl ++ ", " ++ dmUrl)

                                        urls ->
                                            Err ("Expected a notification for the mention and the DM, got " ++ String.fromInt (List.length urls))
                            )
                        , admin.click 100 (Dom.id "guild_openSlackChannel_C09DJDQSWLU")
                        , E2EHelper.hasExactText admin [ "Not for you" ]
                        , admin.click 100 (Dom.id "guild_openSlackChannel_C09DJDQUKKN")
                        , hasNotificationCount admin "guild_openSlackChannel_C09DJDQSWLU" Nothing
                        , T.checkBackend
                            100
                            (\backend ->
                                if adminSlackMentionCount backend == 0 then
                                    Ok ()

                                else
                                    Err "Opening the channel should clear its mention"
                            )
                        , admin.click 100 (Dom.id "guildsColumn_openSlackDm_D09DK3P5RPC")
                        , E2EHelper.hasExactText admin [ "Psst" ]
                        , admin.click 100 (Dom.id "guild_openSlackWorkspace_T09DJDQL18U")
                        , hasNotificationCount admin "guildsColumn_openSlackDm_D09DK3P5RPC" Nothing
                        ]
                    )
                , E2EHelper.checkNoErrorLogs
                ]
            )
        ]


slackThreadReplyEvent : { ts : String, text : String } -> String
slackThreadReplyEvent { ts, text } =
    """{"type":"message","channel":"C09DJDQSWLU","text":\""""
        ++ text
        ++ """ <@U09DJDQL1A8>","blocks":[{"type":"rich_text","block_id":"abc","elements":[{"type":"rich_text_section","elements":[{"type":"text","text":\""""
        ++ text
        ++ """ "},{"type":"user","user_id":"U09DJDQL1A8"}]}]}],"user":"U09DK3NCPMG","team":"T09DJDQL18U","event_ts":\""""
        ++ ts
        ++ """","ts":\""""
        ++ ts
        ++ """","thread_ts":"1791638760.000100","parent_user_id":"U09DJDQL1A8"}"""


allTestSlackThreadMessageCount : E2EHelper.BackendModel2 -> Int
allTestSlackThreadMessageCount backend =
    SeqDict.get (Slack.Id "T09DJDQL18U") (E2EHelper.unwrapBackend backend).slackWorkspaces
        |> Maybe.andThen (\workspace -> SeqDict.get (Slack.Id "C09DJDQSWLU") workspace.channels)
        |> Maybe.andThen (\channel -> SeqDict.get (Id.fromInt 2) channel.threads)
        |> Maybe.map (\thread -> IdArray.length thread.messages)
        |> Maybe.withDefault 0


slackThreadsTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
slackThreadsTest config =
    E2EHelper.startTest
        "Slack threads can be read and replied to, and replies elsewhere show up live"
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
                , T.checkBackend
                    100
                    (\backend ->
                        if allTestSlackThreadMessageCount backend == 2 then
                            Ok ()

                        else
                            Err "Expected the thread's replies to be loaded when the account was linked"
                    )
                , admin.click 100 (Dom.id "guild_openSlackWorkspace_T09DJDQL18U")
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_2")
                , E2EHelper.hasExactText admin [ "First reply", "Second reply" ]
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_C09DJDQSWLU_2" ])
                , E2EHelper.writeMessage admin 100 "Reply from at-chat"
                , E2EHelper.hasExactText admin [ "Reply from at-chat" ]
                , T.checkState
                    100
                    (\data ->
                        let
                            replyRequests : List E2EHelper.CustomRequest
                            replyRequests =
                                List.filterMap
                                    (\request ->
                                        case E2EHelper.decodeCustomRequest request of
                                            Just customRequest ->
                                                if
                                                    String.endsWith "chat.postMessage" customRequest.url
                                                        && List.member "thread_ts=1791638760.000100" (E2EHelper.slackFormFields customRequest.body)
                                                then
                                                    Just customRequest

                                                else
                                                    Nothing

                                            Nothing ->
                                                Nothing
                                    )
                                    data.httpRequests
                        in
                        if List.length replyRequests /= 1 then
                            Err "Expected the reply to be posted to Slack in the thread"

                        else if allTestSlackThreadMessageCount data.backend /= 3 then
                            Err "Expected the reply to be stored in the thread"

                        else
                            Ok ()
                    )
                , admin.click 100 (Dom.id "guild_openSlackChannel_C09DJDQUKKN")
                , E2EHelper.hasExactText admin [ "This is the start of #social" ]
                , hasNotificationCount admin "guild_openSlackChannel_C09DJDQSWLU" Nothing
                , E2EHelper.andThenWebsocket
                    100
                    (\connection _ ->
                        [ T.websocketSendString 100 connection "relay_ready"
                        , T.websocketSendString 100 connection """{"type":"hello"}"""
                        , T.websocketSendString
                            100
                            connection
                            (slackThreadReplyEvent { ts = "1791640001.000100", text = "Thread news" })
                        , hasNotificationCount admin "guild_viewThread_C09DJDQSWLU_2" (Just "1")
                        , hasNotificationCount admin "guild_openSlackChannel_C09DJDQSWLU" Nothing
                        , T.checkBackend
                            100
                            (\backend ->
                                if adminSlackMentionCount backend /= 1 then
                                    Err "Expected the mention in the thread to be counted"

                                else if allTestSlackThreadMessageCount backend /= 4 then
                                    Err "Expected the reply from Slack to be added to the thread"

                                else
                                    Ok ()
                            )
                        , admin.click 100 (Dom.id "guild_viewThread_C09DJDQSWLU_2")
                        , E2EHelper.hasExactText admin [ "Thread news " ]
                        , T.checkBackend
                            100
                            (\backend ->
                                if adminSlackMentionCount backend == 0 then
                                    Ok ()

                                else
                                    Err "Opening the thread should clear its mention"
                            )
                        , T.websocketSendString
                            100
                            connection
                            """{"type":"message","subtype":"message_changed","channel":"C09DJDQSWLU","message":{"user":"U09DK3NCPMG","type":"message","edited":{"user":"U09DK3NCPMG","ts":"1791640010.000000"},"text":"Edited reply","blocks":[{"type":"rich_text","block_id":"abc","elements":[{"type":"rich_text_section","elements":[{"type":"text","text":"Edited reply"}]}]}],"ts":"1791640001.000100","thread_ts":"1791638760.000100"},"event_ts":"1791640010.000200","ts":"1791640010.000200"}"""
                        , E2EHelper.hasExactText admin [ "Edited reply" ]
                        , T.websocketSendString
                            100
                            connection
                            """{"type":"message","subtype":"message_deleted","previous_message":{"user":"U09DK3NCPMG","type":"message","ts":"1791640001.000100","thread_ts":"1791638760.000100","text":"Edited reply"},"channel":"C09DJDQSWLU","hidden":true,"deleted_ts":"1791640001.000100","event_ts":"1791640020.000400","ts":"1791640020.000400"}"""
                        , E2EHelper.hasNotExactText admin [ "Edited reply" ]
                        ]
                    )
                , E2EHelper.checkNoErrorLogs
                ]
            )
        ]


slackWorkspaceAndDmCount : E2EHelper.BackendModel2 -> ( Int, Int )
slackWorkspaceAndDmCount backend =
    ( SeqDict.size (E2EHelper.unwrapBackend backend).slackWorkspaces
    , SeqDict.size (E2EHelper.unwrapBackend backend).slackDmChannels
    )


openSlackAdminSections : T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2)
openSlackAdminSections adminPage =
    [ T.andThen
        10
        (\data ->
            [ adminPage.portEvent
                10
                "load_startup_data_from_js"
                (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
            ]
        )
    , adminPage.click 100 (Pages.Admin.expandSectionButtonId Pages.Admin.SlackWorkspacesSection)
    , adminPage.click 100 (Pages.Admin.expandSectionButtonId Pages.Admin.SlackDmChannelsSection)
    , E2EHelper.hasExactText adminPage [ "test-slack", "Members:" ]
    ]


orphanedSlackWorkspacesTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
orphanedSlackWorkspacesTest config =
    E2EHelper.startTest
        "Hourly update deletes Slack workspaces and DMs that no linked Slack user stayed in for an hour"
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
                , T.andThen 100 (\data -> [ T.backendUpdate 0 (Types.HourlyUpdate data.time) ])
                , T.andThen 100 (\data -> [ T.backendUpdate 0 (Types.HourlyUpdate data.time) ])
                , T.checkBackend
                    100
                    (\backend ->
                        if slackWorkspaceAndDmCount backend == ( 1, 3 ) then
                            Ok ()

                        else
                            Err "Slack workspaces and DMs with a linked member should be kept"
                    )
                , T.connectFrontend
                    100
                    E2EHelper.sessionId0
                    "/admin"
                    E2EHelper.desktopWindow
                    (\adminPage -> openSlackAdminSections adminPage ++ [ E2EHelper.hasNotExactText adminPage [ "Orphaned" ] ])
                , admin.update 100 (Audio.userMsg (Types.PressedUnlinkSlackUser adminSlackUserId))
                , T.connectFrontend
                    100
                    E2EHelper.sessionId0
                    "/admin"
                    E2EHelper.desktopWindow
                    (\adminPage ->
                        openSlackAdminSections adminPage
                            ++ [ adminPage.checkView
                                    100
                                    (\html -> Test.Html.Query.findAll [ Test.Html.Selector.exactText "Orphaned" ] html |> Test.Html.Query.count (Expect.equal 4))
                               ]
                    )
                , T.andThen 100 (\data -> [ T.backendUpdate 0 (Types.HourlyUpdate data.time) ])
                , T.checkBackend
                    100
                    (\backend ->
                        if slackWorkspaceAndDmCount backend == ( 1, 3 ) then
                            Ok ()

                        else
                            Err "Slack workspaces and DMs orphaned since the last hourly update should be kept for another hour"
                    )
                , T.andThen 100 (\data -> [ T.backendUpdate 0 (Types.HourlyUpdate data.time) ])
                , T.checkBackend
                    100
                    (\backend ->
                        if slackWorkspaceAndDmCount backend == ( 0, 0 ) then
                            Ok ()

                        else
                            Err "Slack workspaces and DMs orphaned over two hourly updates should be deleted"
                    )
                ]
            )
        ]


{-| The form fields of each request to a Slack endpoint, leaving out the token.
-}
slackRequestsTo : String -> T.Data FrontendModel E2EHelper.BackendModel2 -> List (List String)
slackRequestsTo endpoint data =
    List.filterMap
        (\request ->
            case E2EHelper.decodeCustomRequest request of
                Just customRequest ->
                    if String.endsWith endpoint customRequest.url then
                        E2EHelper.slackFormFields customRequest.body
                            |> List.filter (\field -> not (String.startsWith "token=" field))
                            |> Just

                    else
                        Nothing

                Nothing ->
                    Nothing
        )
        data.httpRequests


{-| Who reacted with each emoji to the "code" message in #all-test-slack, by Slack emoji name.
-}
codeMessageReactions : E2EHelper.BackendModel2 -> List ( String, List String )
codeMessageReactions backend =
    case
        SeqDict.get (Slack.Id "T09DJDQL18U") (E2EHelper.unwrapBackend backend).slackWorkspaces
            |> Maybe.andThen (\workspace -> SeqDict.get (Slack.Id "C09DJDQSWLU") workspace.channels)
            |> Maybe.andThen (\channel -> IdArray.get (Id.fromInt 3) channel.messages)
    of
        Just (UserTextMessage data) ->
            SeqDict.toList data.reactions
                |> List.map
                    (\( emoji, users ) ->
                        ( case emoji of
                            Emoji.EmojiOrCustomEmoji_Emoji unicodeEmoji ->
                                SlackEmoji.toSlackName unicodeEmoji |> Maybe.withDefault "unknown"

                            Emoji.EmojiOrCustomEmoji_CustomEmoji _ ->
                                "custom"
                        , NonemptySet.toList users |> List.map Slack.idToString |> List.sort
                        )
                    )
                |> List.sortBy Tuple.first

        _ ->
            []


slackReactionEvent : String -> String -> String
slackReactionEvent eventType reaction =
    """{"type":\""""
        ++ eventType
        ++ """","user":"U09DK3NCPMG","reaction":\""""
        ++ reaction
        ++ """","item_user":"U09DJDQL1A8","item":{"type":"message","channel":"C09DJDQSWLU","ts":"1791638770.000100"},"event_ts":"1791640100.000100"}"""


slackReactionsAndNewThreadTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
slackReactionsAndNewThreadTest config =
    E2EHelper.startTest
        "Slack reactions can be added and removed both ways, a Slack message can start a thread, and your own Slack messages can be deleted"
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
                , T.checkBackend
                    100
                    (\backend ->
                        if
                            codeMessageReactions backend
                                == [ ( "+1", [ "U09DK3NCPMG" ] ), ( "wave::skin-tone-3", [ "U09DJDQL1A8", "U09DK3NCPMG" ] ) ]
                        then
                            Ok ()

                        else
                            Err "Expected the reactions from Slack's history without the custom emoji"
                    )
                , E2EHelper.hasExactText admin [ "👍", "👋🏼" ]
                , admin.mouseEnter 100 (Dom.id "guild_message_3") ( 10, 10 ) []
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "miniView_reply" ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "miniView_editMessage" ])
                , admin.click 100 (Dom.id "miniView_emojiReact_0")
                , T.checkState
                    100
                    (\data ->
                        if slackRequestsTo "reactions.add" data /= [ [ "channel=C09DJDQSWLU", "timestamp=1791638770.000100", "name=heart" ] ] then
                            Err "Expected the reaction to be sent to Slack"

                        else if not (List.member ( "heart", [ "U09DJDQL1A8" ] ) (codeMessageReactions data.backend)) then
                            Err "Expected the reaction to be stored"

                        else
                            Ok ()
                    )
                , admin.click 100 (Dom.id "miniView_emojiReact_0")
                , T.checkState
                    100
                    (\data ->
                        if slackRequestsTo "reactions.remove" data /= [ [ "channel=C09DJDQSWLU", "timestamp=1791638770.000100", "name=heart" ] ] then
                            Err "Expected the reaction to be removed on Slack"

                        else if List.any (\( name, _ ) -> name == "heart") (codeMessageReactions data.backend) then
                            Err "Expected the reaction to be removed"

                        else
                            Ok ()
                    )
                , admin.mouseLeave 100 (Dom.id "guild_message_3") ( 10, 10 ) []
                , E2EHelper.andThenWebsocket
                    100
                    (\connection _ ->
                        [ T.websocketSendString 100 connection "relay_ready"
                        , T.websocketSendString 100 connection """{"type":"hello"}"""
                        , T.websocketSendString 100 connection (slackReactionEvent "reaction_added" "tada")
                        , E2EHelper.hasExactText admin [ "🎉" ]
                        , T.websocketSendString 100 connection (slackReactionEvent "reaction_removed" "+1")
                        , E2EHelper.hasNotExactText admin [ "👍" ]
                        , T.checkBackend
                            100
                            (\backend ->
                                if
                                    codeMessageReactions backend
                                        == [ ( "tada", [ "U09DK3NCPMG" ] ), ( "wave::skin-tone-3", [ "U09DJDQL1A8", "U09DK3NCPMG" ] ) ]
                                then
                                    Ok ()

                                else
                                    Err "Expected reactions from Slack's websocket to be stored"
                            )
                        ]
                    )
                , admin.custom
                    100
                    (Dom.id "guild_message_3")
                    "contextmenu"
                    (Json.Encode.object [ ( "clientX", Json.Encode.int 500 ), ( "clientY", Json.Encode.int 300 ) ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_deleteMessage" ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_editMessage" ])
                , admin.click 100 (Dom.id "messageMenu_openThread")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_C09DJDQSWLU_3" ])
                , E2EHelper.writeMessage admin 100 "Starting a thread"
                , E2EHelper.hasExactText admin [ "Starting a thread" ]
                , T.checkState
                    100
                    (\data ->
                        if
                            List.filter
                                (List.member "thread_ts=1791638770.000100")
                                (slackRequestsTo "chat.postMessage" data)
                                |> List.length
                                |> (/=) 1
                        then
                            Err "Expected the reply to be posted to Slack in a new thread"

                        else if
                            SeqDict.get (Slack.Id "T09DJDQL18U") (E2EHelper.unwrapBackend data.backend).slackWorkspaces
                                |> Maybe.andThen (\workspace -> SeqDict.get (Slack.Id "C09DJDQSWLU") workspace.channels)
                                |> Maybe.andThen (\channel -> SeqDict.get (Id.fromInt 3) channel.threads)
                                |> Maybe.map (\thread -> IdArray.length thread.messages)
                                |> (/=) (Just 1)
                        then
                            Err "Expected the new thread to be stored"

                        else
                            Ok ()
                    )
                , admin.mouseEnter 100 (Dom.id "thread_message_0") ( 10, 10 ) []
                , admin.click 100 (Dom.id "miniView_emojiReact_0")
                , T.checkState
                    100
                    (\data ->
                        if List.member [ "channel=C09DJDQSWLU", "timestamp=1791638900.000100", "name=heart" ] (slackRequestsTo "reactions.add" data) then
                            Ok ()

                        else
                            Err "Expected reacting to a thread reply to be sent to Slack"
                    )
                , admin.mouseLeave 100 (Dom.id "thread_message_0") ( 10, 10 ) []
                , admin.custom
                    100
                    (Dom.id "thread_message_0")
                    "contextmenu"
                    (Json.Encode.object [ ( "clientX", Json.Encode.int 500 ), ( "clientY", Json.Encode.int 300 ) ])
                , admin.click 100 (Dom.id "messageMenu_deleteMessage")
                , E2EHelper.hasNotExactText admin [ "Starting a thread" ]
                , T.checkState
                    100
                    (\data ->
                        if slackRequestsTo "chat.delete" data /= [ [ "channel=C09DJDQSWLU", "ts=1791638900.000100" ] ] then
                            Err "Expected the message to be deleted on Slack"

                        else
                            case
                                SeqDict.get (Slack.Id "T09DJDQL18U") (E2EHelper.unwrapBackend data.backend).slackWorkspaces
                                    |> Maybe.andThen (\workspace -> SeqDict.get (Slack.Id "C09DJDQSWLU") workspace.channels)
                                    |> Maybe.andThen (\channel -> SeqDict.get (Id.fromInt 3) channel.threads)
                                    |> Maybe.andThen (\thread -> IdArray.get (Id.fromInt 0) thread.messages)
                            of
                                Just (DeletedMessage _) ->
                                    Ok ()

                                _ ->
                                    Err "Expected the message to be deleted"
                    )
                , admin.click 100 (Dom.id "guild_openSlackChannel_C09DJDQSWLU")
                , admin.custom
                    100
                    (Dom.id "guild_message_4")
                    "contextmenu"
                    (Json.Encode.object [ ( "clientX", Json.Encode.int 500 ), ( "clientY", Json.Encode.int 300 ) ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copy" ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_deleteMessage" ])
                , E2EHelper.checkNoErrorLogs
                ]
            )
        ]
