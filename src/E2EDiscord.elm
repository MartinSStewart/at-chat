module E2EDiscord exposing (discordTests)

import Array
import Audio
import Backend
import Codec
import CustomEmoji exposing (CustomEmojiData)
import Discord
import Drawing
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Websocket as Websocket
import Emoji exposing (EmojiOrCustomEmoji(..))
import Expect
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), GuildOrDmId(..), ThreadRoute(..))
import IdArray
import Iso8601
import LinkedAndOtherDiscordUsers
import Local
import LocalState
import MembersAndOwner
import Message
import MessageInput
import Pages.Guild
import PersonName
import Route
import SeqDict
import Sticker
import Test.Html.Query
import Test.Html.Selector
import Time
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import Unsafe
import User


{-| Runs the given function against the admin frontend's LocalState, surfacing a
descriptive error if the admin isn't loaded/logged in.
-}
withAdminLocalState :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.Data FrontendModel BackendModel
    -> (LocalState.LocalState -> Result String ())
    -> Result String ()
withAdminLocalState admin data fn =
    case SeqDict.get admin.clientId data.frontends |> Maybe.map Audio.userModel of
        Just (Types.Loaded loaded) ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    fn (Local.model loggedIn.localState)

                _ ->
                    Err "Expected admin to be logged in"

        _ ->
            Err "Expected admin frontend to be loaded"


checkDmVisibleMessageCountDmChannelId : Discord.Id Discord.PrivateChannelId
checkDmVisibleMessageCountDmChannelId =
    Unsafe.uint64 "185574444641550336" |> Discord.idFromUInt64


{-| Reads the number of currently visible messages in the at0232 Discord DM channel
(id 185574444641550336) from the admin frontend and checks it against a predicate.
-}
checkDmVisibleMessageCount :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> (Int -> Bool)
    -> T.Data FrontendModel BackendModel
    -> Result String ()
checkDmVisibleMessageCount admin isExpected data =
    withAdminLocalState admin
        data
        (\local ->
            case SeqDict.get checkDmVisibleMessageCountDmChannelId local.discordDmChannels of
                Just dmChannel ->
                    if isExpected dmChannel.visibleMessages.count then
                        Ok ()

                    else
                        Err
                            ("Discord DM visibleMessages.count="
                                ++ String.fromInt dmChannel.visibleMessages.count
                                ++ " while the messages array still holds "
                                ++ String.fromInt (IdArray.length dmChannel.messages)
                                ++ " message(s). HandleReadyDataStep2 wiped the visible messages of the open DM, so they disappear from view."
                            )

                Nothing ->
                    Err "The Discord DM channel is missing from the frontend"
        )


checkGuildVisibleMessageCountGuildId : Discord.Id Discord.GuildId
checkGuildVisibleMessageCountGuildId =
    Unsafe.uint64 "705745250815311942" |> Discord.idFromUInt64


checkGuildVisibleMessageCountChannelId : Discord.Id Discord.ChannelId
checkGuildVisibleMessageCountChannelId =
    Unsafe.uint64 "1072828564317159465" |> Discord.idFromUInt64


{-| Reads the number of currently visible messages in the bot test guild's channel
(guild 705745250815311942, channel 1072828564317159465) from the admin frontend and
checks it against a predicate.
-}
checkGuildVisibleMessageCount :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> (Int -> Bool)
    -> T.Data FrontendModel BackendModel
    -> Result String ()
checkGuildVisibleMessageCount admin isExpected data =
    withAdminLocalState admin
        data
        (\local ->
            case LocalState.getDiscordGuildAndChannel checkGuildVisibleMessageCountGuildId checkGuildVisibleMessageCountChannelId local of
                Just ( _, channel ) ->
                    if isExpected channel.visibleMessages.count then
                        Ok ()

                    else
                        Err
                            ("Discord guild channel visibleMessages.count="
                                ++ String.fromInt channel.visibleMessages.count
                                ++ " while the messages array still holds "
                                ++ String.fromInt (IdArray.length channel.messages)
                                ++ " message(s). HandleReadyDataStep2 wiped the visible messages of the open guild channel, so they disappear from view."
                            )

                Nothing ->
                    Err "The Discord guild channel is missing from the frontend"
        )


{-| Id of the private channel created during the "private channel access" test.
-}
privateDiscordChannelId : Discord.Id Discord.ChannelId
privateDiscordChannelId =
    Unsafe.uint64 "1500000000000000777" |> Discord.idFromUInt64


{-| A CHANNEL\_CREATE gateway event for a private channel in the Bot Test guild
(705745250815311942). The @everyone role (whose id equals the guild id) is denied
View Channel (permission bit 10 = 1024) and only the admin's linked Discord
account (184437096813953035) is granted it through a member overwrite, so no
other guild member can see the channel on Discord.
-}
privateDiscordChannelCreateEvent : String
privateDiscordChannelCreateEvent =
    """{"t":"CHANNEL_CREATE","s":90,"op":0,"d":{"id":"1500000000000000777","type":0,"guild_id":"705745250815311942","name":"secret-channel","position":10,"topic":null,"parent_id":null,"nsfw":false,"last_message_id":null,"permission_overwrites":[{"id":"705745250815311942","type":0,"allow":"0","deny":"1024"},{"id":"184437096813953035","type":1,"allow":"1024","deny":"0"}]}}"""


discordTests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
discordTests normalConfig discordOp0Ready discordOp0ReadySupplemental =
    [ E2EHelper.startTest
        "Got rich text embed"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":173,"op":0,"d":{"webhook_id":"1374332266083254363","type":0,"tts":false,"timestamp":"2026-04-16T01:36:56.515000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"id":"1494149566100930611","flags":0,"embeds":[{"type":"rich","title":"[compiler] Branch distribute was force-pushed to `c7b3d5e`","id":"1494149566100930612","description":"[Compare changes](https://github.com/lamdera/compiler/compare/01daaf8875d1...c7b3d5e6f412)","content_scan_version":4,"color":16525609,"author":{"url":"https://github.com/supermario","proxy_icon_url":"https://images-ext-1.discordapp.net/external/EOjvf3Ly7SSCVe7o-8EBJBz6V_MUyiX7n4TkBiIkZnI/%3Fv%3D4/https/avatars.githubusercontent.com/u/102781","name":"supermario","icon_url":"https://avatars.githubusercontent.com/u/102781?v=4"}}],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"GitHub","id":"1374332266083254363","global_name":null,"discriminator":"0000","bot":true,"avatar":"e57fd67dc7ca0cc840a0e87a82281bc5"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.find [ Test.Html.Selector.id "spoiler_0_0" ] html
                                    |> Test.Html.Query.hasNot [ Test.Html.Selector.tag "img" ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Message with new custom emoji"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        let
                            customEmojiNamed : String -> T.Data FrontendModel BackendModel -> List CustomEmojiData
                            customEmojiNamed name data =
                                SeqDict.values data.backend.customEmojis
                                    |> List.filter (\customEmoji -> CustomEmoji.emojiNameToString customEmoji.name == name)
                        in
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.checkState
                            100
                            (\data ->
                                if List.isEmpty (customEmojiNamed "newemoji" data) then
                                    Ok ()

                                else
                                    Err "Backend already has the new custom emoji loaded before the message was sent"
                            )
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-29T00:00:00.000000+00:00\",\"pinned\":false,\"nonce\":\"1500000000000000000\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1500000000000000001\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Hello <:newemoji:888159336168300599>\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "Custom emoji failed to load" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "Hello" ])
                        , T.checkState
                            100
                            (\data ->
                                case customEmojiNamed "newemoji" data of
                                    [ customEmoji ] ->
                                        case customEmoji.url of
                                            CustomEmoji.CustomEmojiInternal _ _ ->
                                                Ok ()

                                            CustomEmoji.CustomEmojiLoading ->
                                                Err "Backend loaded the new custom emoji but it is still in the loading state"

                                    [] ->
                                        Err "Backend did not load the new custom emoji from the message"

                                    _ ->
                                        Err "Backend loaded more than one custom emoji called \"newemoji\""
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Reaction with new custom emoji"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        let
                            customEmojiNamed : String -> T.Data FrontendModel BackendModel -> List CustomEmojiData
                            customEmojiNamed name data =
                                SeqDict.values data.backend.customEmojis
                                    |> List.filter (\customEmoji -> CustomEmoji.emojiNameToString customEmoji.name == name)

                            lastMessageReactions :
                                T.Data FrontendModel BackendModel
                                -> Result String (List EmojiOrCustomEmoji)
                            lastMessageReactions data =
                                case SeqDict.get checkGuildVisibleMessageCountGuildId data.backend.discordGuilds of
                                    Just guild ->
                                        case SeqDict.get checkGuildVisibleMessageCountChannelId guild.channels of
                                            Just channel ->
                                                case IdArray.last channel.messages of
                                                    Just message ->
                                                        Message.reactionEmojis message |> SeqDict.keys |> Ok

                                                    Nothing ->
                                                        Err "The Discord guild channel has no messages"

                                            Nothing ->
                                                Err "The Discord guild channel is missing from the backend"

                                    Nothing ->
                                        Err "The Discord guild is missing from the backend"
                        in
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-29T00:00:00.000000+00:00\",\"pinned\":false,\"nonce\":\"1500000000000000000\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1500000000000000001\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"React to this\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , T.checkState
                            100
                            (\data ->
                                if List.isEmpty (customEmojiNamed "reactemoji" data) then
                                    Ok ()

                                else
                                    Err "Backend already has the reaction's custom emoji loaded before the reaction was added"
                            )
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_REACTION_ADD\",\"s\":5,\"op\":0,\"d\":{\"user_id\":\"161098476632014848\",\"message_id\":\"1500000000000000001\",\"emoji\":{\"id\":\"888159336168300600\",\"name\":\"reactemoji\"},\"channel_id\":\"1072828564317159465\",\"guild_id\":\"705745250815311942\",\"burst\":false}}"
                        , T.checkState
                            100
                            (\data ->
                                case lastMessageReactions data of
                                    Ok [ EmojiOrCustomEmoji_CustomEmoji customEmojiId ] ->
                                        case SeqDict.get customEmojiId data.backend.customEmojis of
                                            Just customEmoji ->
                                                if CustomEmoji.emojiNameToString customEmoji.name == "reactemoji" then
                                                    case customEmoji.url of
                                                        CustomEmoji.CustomEmojiInternal _ _ ->
                                                            Ok ()

                                                        CustomEmoji.CustomEmojiLoading ->
                                                            Err "Backend registered the reaction's custom emoji but it is still in the loading state"

                                                else
                                                    Err
                                                        ("The reaction points at the wrong custom emoji: "
                                                            ++ CustomEmoji.emojiNameToString customEmoji.name
                                                        )

                                            Nothing ->
                                                Err "The reaction's custom emoji id is missing from the backend customEmojis"

                                    Ok [ EmojiOrCustomEmoji_Emoji _ ] ->
                                        Err "The reaction was stored as a unicode emoji (the ❓ fallback) instead of a custom emoji"

                                    Ok [] ->
                                        Err "The reaction is missing from the message"

                                    Ok _ ->
                                        Err "Expected exactly one reaction on the message"

                                    Err error ->
                                        Err error
                            )
                        , T.checkState
                            100
                            (\data ->
                                withAdminLocalState admin
                                    data
                                    (\local ->
                                        case LocalState.getDiscordGuildAndChannel checkGuildVisibleMessageCountGuildId checkGuildVisibleMessageCountChannelId local of
                                            Just ( _, channel ) ->
                                                case IdArray.last channel.messages of
                                                    Just (Message.MessageLoaded message) ->
                                                        case Message.reactionEmojis message |> SeqDict.keys of
                                                            [ EmojiOrCustomEmoji_CustomEmoji _ ] ->
                                                                Ok ()

                                                            [ EmojiOrCustomEmoji_Emoji _ ] ->
                                                                Err "The frontend received the reaction as a unicode emoji (the ❓ fallback) instead of a custom emoji"

                                                            [] ->
                                                                Err "The reaction is missing from the frontend's message"

                                                            _ ->
                                                                Err "Expected exactly one reaction on the frontend's message"

                                                    Just Message.MessageUnloaded ->
                                                        Err "The frontend's copy of the message is unloaded"

                                                    Nothing ->
                                                        Err "The Discord guild channel has no messages on the frontend"

                                            Nothing ->
                                                Err "The Discord guild channel is missing from the frontend"
                                    )
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Got spoilered image"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":3,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-12T13:14:33.237000+00:00","pinned":false,"nonce":"1492875573255471104","mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2020-05-01T11:39:39.915000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1492875574455042168","flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"attachments":[{"width":80,"url":"https://cdn.discordapp.com/attachments/1072828564317159465/1492875574174154943/SPOILER_1122943867721875456.png?ex=69dcec39&is=69db9ab9&hm=992b357861cbb393bf8fdfac2690f576b6283968400d3cd18dd2d9f7e117c65b&","size":492063,"proxy_url":"https://media.discordapp.net/attachments/1072828564317159465/1492875574174154943/SPOILER_1122943867721875456.png?ex=69dcec39&is=69db9ab9&hm=992b357861cbb393bf8fdfac2690f576b6283968400d3cd18dd2d9f7e117c65b&","placeholder_version":1,"placeholder":"ZCmGHQYsRFqRmof6NoZvZ/lnBEaEhnJkWA==","original_content_type":"image/png","id":"1492875574174154943","height":80,"flags":40,"filename":"SPOILER_1122943867721875456.png","content_type":"image/png","content_scan_version":4}],"guild_id":"705745250815311942"}}"""
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.find [ Test.Html.Selector.id "spoiler_0_0" ] html
                                    |> Test.Html.Query.hasNot [ Test.Html.Selector.tag "img" ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Message created by unlinked user containing only embed"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":476,"op":0,"d":{"webhook_id":"1374332266083254363","type":0,"tts":false,"timestamp":"2026-03-31T20:15:05.862000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"id":"1488632753368072280","flags":0,"embeds":[{"url":"https://github.com/lamdera/compiler/pull/92","type":"rich","title":"[lamdera/compiler] Pull request opened: #92   Allow configuring <html lang> via html-lang file","id":"1488632753368072281","description":"Read an optional html-lang file from the project root to set the lang attribute on the generated  tag.  If the file contains e.g. \\"fr\\", the output becomes .  If absent or empty, the tag is plain  as before.  Fixes #84.","content_scan_version":4,"color":38912,"author":{"url":"https://github.com/MavenRain","proxy_icon_url":"https://images-ext-1.discordapp.net/external/z5iI09eMZ6hW8pY8xflOmWevOiHuXRD-pljR_thC38Q/%3Fv%3D4/https/avatars.githubusercontent.com/u/7246681","name":"MavenRain","icon_url":"https://avatars.githubusercontent.com/u/7246681?v=4"}}],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"GitHub","id":"1374332266083254363","global_name":null,"discriminator":"0000","bot":true,"avatar":"e57fd67dc7ca0cc840a0e87a82281bc5"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Title for https://github.com/lamdera/compiler/pull/92" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord friend label shows typing indicator"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guildIcon_showFriends")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.exactText "Typing..." ]
                            )
                        , T.websocketSendString 100 connection "{\"t\":\"TYPING_START\",\"s\":3,\"op\":0,\"d\":{\"channel_id\":\"185574444641550336\",\"user_id\":\"161098476632014848\",\"timestamp\":1}}"
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Typing..." ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord DM and guild messages survive websocket reconnect (HandleReadyDataStep2)"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ -- Open a Discord guild channel and load a message into it.
                          admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":199,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:00:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1500000000000000199","flags":0,"embeds":[],"edited_timestamp":null,"content":"Guild message that should survive reconnect","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Guild message that should survive reconnect" ])

                        -- Open the Discord DM channel with at0232 and load a message into it.
                        , admin.click 100 (Dom.id "guildIcon_showFriends")
                        , admin.click 100 (Dom.id "guild_discordFriendLabel_185574444641550336")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":200,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:00:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"id":"1500000000000000200","flags":0,"embeds":[],"edited_timestamp":null,"content":"DM message that should survive reconnect","components":[],"channel_type":1,"channel_id":"185574444641550336","author":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"attachments":[]}}"""

                        -- The message is loaded and visible in the open DM channel.
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "DM message that should survive reconnect" ])

                        -- Sanity check: both messages really are loaded into their conversations
                        -- (visibleMessages is non-empty), not merely shown as a friend-list preview.
                        , T.checkState 0 (checkDmVisibleMessageCount admin (\count -> count > 0))
                        , T.checkState 0 (checkGuildVisibleMessageCount admin (\count -> count > 0))

                        -- The Discord websocket "fails": send op 9 (Invalid Session) which clears
                        -- the gateway session and forces a fresh reconnect (rather than a resume).
                        , T.websocketSendString 100 connection """{"t":null,"s":null,"op":9,"d":false}"""
                        ]
                    )

                -- A brand new gateway connection is created after the reconnect. Complete the
                -- handshake on it (hello -> identify) and replay the READY data, which triggers
                -- HandleReadyDataStep2 again.
                , E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ T.websocketSendString 100 connection """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}""" ]
                    )
                , E2EHelper.andThenWebsocket
                    (\connection websocketState ->
                        case Array.toList websocketState.dataSent |> List.filter E2EHelper.isOp2 of
                            [ _ ] ->
                                [ T.websocketSendString 100 connection discordOp0Ready
                                , T.websocketSendString 100 connection discordOp0ReadySupplemental
                                ]

                            _ ->
                                [ T.checkState 0 (\_ -> Err "Wrong number of Discord connections made") ]
                    )

                -- Regression check for the bug where HandleReadyDataStep2 rebroadcast every Discord
                -- DM/guild with preloadMessages = False, and the frontend (FrontendExtra,
                -- Server_DiscordUserLoadingDataIsDone) blindly overwrote its copy of each channel with
                -- `SeqDict.foldl SeqDict.insert`. That reset visibleMessages to empty for the open
                -- channel, and because visibleMessages.oldest is 0 no "load older messages" request is
                -- ever made, so the messages disappear for good even though the backend still has them.
                --
                -- The fix only rebroadcasts brand new guilds/DMs, so the messages that were loaded
                -- before the reconnect must still be visible afterwards, for both the DM and the guild
                -- channel.
                , T.checkState 3000 (checkDmVisibleMessageCount admin (\count -> count > 0))
                , T.checkState 0 (checkGuildVisibleMessageCount admin (\count -> count > 0))
                ]
            )
        ]
    , E2EHelper.startTest
        "Message created by linked user containing url"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , E2EHelper.writeMessage admin 100 "https://www.youtube.com/watch?v=zAFDQH19pV4"
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":3,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-01T10:04:25.211000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1488841459204489398","flags":0,"embeds":[],"edited_timestamp":null,"content":"https://www.youtube.com/watch?v=zAFDQH19pV4","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , T.websocketSendString 1000 connection """{"t":"MESSAGE_UPDATE","s":4,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-01T10:04:25.211000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1488841459204489398","flags":0,"embeds":[{"video":{"width":720,"url":"https://www.youtube.com/embed/zAFDQH19pV4","placeholder_version":1,"placeholder":"lDgKDIQHiJZyiniCe3ingHsKqA==","height":720,"flags":0},"url":"https://www.youtube.com/watch?v=zAFDQH19pV4","type":"video","title":"Spiral (jackLNDN Remix)","thumbnail":{"width":1280,"url":"https://i.ytimg.com/vi/zAFDQH19pV4/maxresdefault.jpg","proxy_url":"https://images-ext-1.discordapp.net/external/o1Bl70OhMLyAuYI0AvggMLdse0h4epFkr-Nd4Ru9L3I/https/i.ytimg.com/vi/zAFDQH19pV4/maxresdefault.jpg","placeholder_version":1,"placeholder":"lDgKDIQHiJZyiniCe3ingHsKqA==","height":720,"flags":0,"content_type":"image/jpeg"},"provider":{"url":"https://www.youtube.com","name":"YouTube"},"id":"1488841460739739829","description":"Provided to YouTube by Label Worx Limited\\n\\nSpiral (jackLNDN Remix) · Lena Leon · jackLNDN · jackLNDN\\n\\nSpiral (Deluxe Edition)\\n\\n℗ Big Proof Publishing, Danny Danger Publishing, Ultra Empire Music (BMI) obo itself and LRL Music, Whizz Kid II Publishing GmbH, Hooks & Crooks BMG Rights Management GmbH\\n\\nReleased on: 2023-02-10\\n\\nProducer: jackLND...","color":16711680,"author":{"url":"https://www.youtube.com/channel/UCQ8EctjrppQcwBA3lEIlk4w","name":"Lena Leon - Topic"}}],"edited_timestamp":null,"content":"https://www.youtube.com/watch?v=zAFDQH19pV4","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Title for https://www.youtube.com/watch?v=zAFDQH19pV4" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Edit Discord message by pressing up arrow in channel input"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")

                        -- Six messages interleaved between the currently logged in Discord user
                        -- (at28727 / id 184437096813953035) and another user (at0232 / id 161098476632014848),
                        -- with the other user sending the most recent message. Pressing up should skip the
                        -- other user's messages and edit the logged in user's own most recent message.
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":50,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:00:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1500000000000000001","flags":0,"embeds":[],"edited_timestamp":null,"content":"Discord admin one","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":51,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:01:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2020-05-01T11:39:39.915000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1500000000000000002","flags":0,"embeds":[],"edited_timestamp":null,"content":"Discord other one","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":52,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:02:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1500000000000000003","flags":0,"embeds":[],"edited_timestamp":null,"content":"Discord admin two","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":53,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:03:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2020-05-01T11:39:39.915000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1500000000000000004","flags":0,"embeds":[],"edited_timestamp":null,"content":"Discord other two","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":54,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:04:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1500000000000000005","flags":0,"embeds":[],"edited_timestamp":null,"content":"Discord admin three","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":55,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:05:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2020-05-01T11:39:39.915000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1500000000000000006","flags":0,"embeds":[],"edited_timestamp":null,"content":"Discord other three","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Discord admin three" ])
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Discord other three" ])
                        , E2EHelper.editMostRecentMessageViaArrowUp admin "Discord admin three" "Discord admin three edited"

                        -- Only the logged in user's most recent message was edited; the others are untouched.
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Discord admin three" ])
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Discord admin one" ])
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Discord other three" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Link Discord account with login"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\_ -> [])
        ]
    , E2EHelper.startTest "Forwarded message"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":3293,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-17T16:14:03.131000+00:00","pinned":false,"nonce":"1494732679017398272","message_snapshots":[{"message":{"type":0,"timestamp":"2026-04-17T11:22:04.856000+00:00","mentions":[],"flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"attachments":[{"width":2160,"url":"https://cdn.discordapp.com/attachments/123/321/IMG_1234.jpg?ex=123&is=321&hm=123&","size":517431,"proxy_url":"https://media.discordapp.net/attachments/123/321/1234.jpg?ex=123&is=321&hm=123&","placeholder_version":1,"placeholder":"WlkKDgSql6d2d3d4d4B4gZqYrHCJCGc=","id":"1494732685631946782","height":2461,"filename":"IMG_7203.jpg","content_type":"image/jpeg","content_scan_version":4}]}}],"message_reference":{"type":1,"message_id":"1494659209021751327","channel_id":"1472236476401057854"},"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":["476506921260810240","734405273103499264","743849378363605082","840010386958581770","776291214478802964","840041852852895765","1030137708531687514"],"premium_since":null,"pending":false,"nick":"cute technology","mute":false,"joined_at":"2018-08-07T17:00:17.616000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1494732685992530114","flags":16384,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"capysuit","public_flags":0,"primary_guild":null,"id":"339560235050205185","global_name":"gio","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7d2709668c67727f98ba40ff62611e78"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 1000 (Test.Html.Query.hasNot [ Test.Html.Selector.text "empty" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Message with sticker"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , admin.click 100 (Dom.id "messageMenu_channelInput_openEmojiSelector")
                        , admin.click 100 (Dom.id "emoji_category_Stickers")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.tag "lottie-player" ])
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.tag "animated-image-player" ] html
                                    |> Test.Html.Query.count (Expect.equal 2)
                            )
                        , admin.click 100 (Dom.id "elm-ui-root-id")
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-07T23:35:37.476000+00:00\",\"sticker_items\":[{\"name\":\"sticker1\",\"id\":\"1490687750288965813\",\"format_type\":2}],\"pinned\":false,\"nonce\":\"1491219931943927808\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1491219932673740970\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Message with text and sticker!\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.text "Sticker failed to load"
                                , Test.Html.Selector.tag "lottie-player"
                                ]
                            )
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Message with text and sticker!" ])
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":5,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-07T23:36:41.898000+00:00\",\"sticker_items\":[{\"name\":\"Happy\",\"id\":\"796140620111544330\",\"format_type\":3}],\"pinned\":false,\"nonce\":\"1491220202350706688\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1491220202879324241\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.tag "lottie-player" ])
                        ]
                    )
                ]
            )
        , T.connectFrontend
            100
            E2EHelper.sessionId0
            (Route.encode
                (Route.DiscordGuildRoute
                    { currentDiscordUserId = E2EHelper.currentDiscordUserId
                    , guildId = E2EHelper.botTestGuild
                    , channelRoute =
                        Route.DiscordChannel_ChannelRoute
                            E2EHelper.botTestGuild_ChannelA
                            (Route.NoThreadWithFriends Nothing Route.ShowMembersTab)
                            Nothing
                    }
                )
            )
            E2EHelper.desktopWindow
            (\admin ->
                [ T.andThen
                    10
                    (\data -> [ admin.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.text "Sticker failed to load" ])
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.tag "lottie-player"
                        , Test.Html.Selector.exactText "Message with text and sticker!"
                        ]
                    )
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ admin.click 100 (Dom.id "guild_openChannel_0")
                        , admin.click 100 (Dom.id "messageMenu_channelInput_openEmojiSelector")
                        , admin.click 100 (Dom.id "emoji_category_Stickers")
                        , admin.click 100 (Dom.id "guild_emojiSelector_0")
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.tag "animated-image-player" ])
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.tag "animated-image-player" ])
                        , T.andThen
                            30
                            (\data ->
                                case
                                    List.filter
                                        (\request -> request.clientId == admin.clientId && request.portName == "exec_command_to_js")
                                        data.portRequests
                                of
                                    [ _ ] ->
                                        [ admin.update
                                            30
                                            (Types.MessageInputMsg
                                                (GuildOrDmId (GuildOrDmId_Guild (Id.fromInt 0) (Id.fromInt 0)))
                                                NoThread
                                                (MessageInput.TypedMessage (Sticker.idToString (Id.fromInt 3)))
                                                |> Audio.userMsg
                                            )
                                        , admin.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                                        ]

                                    _ ->
                                        [ admin.checkModel 100 (\_ -> Err "Didn't add sticker to text input") ]
                            )
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.tag "animated-image-player" ])
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.tag "animated-image-player" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Link Discord account with login to non-existent at-chat account"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            "Steve"
            E2EHelper.userEmail
            True
            discordOp0Ready
            discordOp0ReadySupplemental
            (\user ->
                [ user.click 100 (Dom.id "guild_showUserOptions")
                , user.click 100 (Dom.id "userOptions_discordSection")
                , user.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "at0232"
                        , Test.Html.Selector.exactText "a@a.se"
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Link Discord account already logged in"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\adminA ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail adminA
                , adminA.click 100 (Dom.id "guild_showUserOptions")
                , adminA.click 100 (Dom.id "userOptions_discordSection")
                , adminA.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Loading user data" ])
                , T.connectFrontend
                    100
                    E2EHelper.sessionId0
                    ("/link-discord/?data=" ++ Codec.encodeToString 0 User.linkDiscordDataCodec E2EHelper.discordUserAuth)
                    E2EHelper.desktopWindow
                    (\adminB ->
                        [ T.andThen
                            10
                            (\data -> [ adminB.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , adminA.checkView
                            200
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Loading user data" ])
                        , E2EHelper.andThenWebsocket
                            (\connection _ ->
                                [ T.websocketSendString 100 connection """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}""" ]
                            )
                        , E2EHelper.andThenWebsocket
                            (\connection websocketState ->
                                case Array.toList websocketState.dataSent |> List.filter E2EHelper.isOp2 of
                                    [ _ ] ->
                                        [ T.websocketSendString 100 connection discordOp0Ready
                                        , T.websocketSendString 100 connection discordOp0ReadySupplemental
                                        ]

                                    _ ->
                                        [ T.checkState 0 (\_ -> Err "Wrong number of Discord connections made") ]
                            )
                        , adminB.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText (PersonName.toString Backend.adminUser.name)
                                , Test.Html.Selector.exactText "at0232"
                                , Test.Html.Selector.exactText "kess"
                                , Test.Html.Selector.exactText "purplelite"
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Ping discord user"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\user ->
                [ user.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , user.input 100 Pages.Guild.channelTextInputId "Hello @purplelite!"
                , user.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "@purplelite" ])
                ]
            )
        ]
    , E2EHelper.startTest
        "Unlinked Discord user starts thread from message"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\user ->
                [ user.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T10:56:15.024000+00:00\",\"pinned\":false,\"nonce\":\"1486680174970798080\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"705745250815311942\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread start message\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_UPDATE\",\"s\":5,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T10:56:15.024000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"705745250815311942\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread start message\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"s\":6,\"op\":0,\"d\":{\"user_id\":\"161098476632014848\",\"target_id\":\"705745250815311942\",\"id\":\"1486680242226598131\",\"changes\":[{\"new_value\":\"Custom thread name\",\"key\":\"name\"},{\"new_value\":11,\"key\":\"type\"},{\"new_value\":false,\"key\":\"archived\"},{\"new_value\":false,\"key\":\"locked\"},{\"new_value\":4320,\"key\":\"auto_archive_duration\"},{\"new_value\":0,\"key\":\"rate_limit_per_user\"},{\"new_value\":0,\"key\":\"flags\"}],\"action_type\":110,\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_MEMBERS_UPDATE\",\"s\":7,\"op\":0,\"d\":{\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"id\":\"705745250815311942\",\"added_members\":[{\"user_id\":\"184437096813953035\",\"presence\":{\"user\":{\"username\":\"at28727\",\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"discriminator\":\"0\",\"clan\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"status\":\"online\",\"processed_at_timestamp\":0,\"game\":null,\"client_status\":{\"web\":\"online\"},\"activities\":[]},\"muted\":false,\"mute_config\":null,\"member\":{\"user\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"display_name\":\"AT2\",\"discriminator\":\"0\",\"collectibles\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2025-10-11T19:44:51.312000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"join_timestamp\":\"2026-03-26T10:56:31.471913+00:00\",\"id\":\"705745250815311942\",\"flags\":1}],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_CREATE\",\"s\":8,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-03-26T10:56:30.898915+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-03-26T10:56:30.898915+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"name\":\"Custom thread name\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"member\":{\"user_id\":\"184437096813953035\",\"muted\":false,\"mute_config\":null,\"join_timestamp\":\"2026-03-26T10:56:31.471913+00:00\",\"id\":\"705745250815311942\",\"flags\":1},\"last_message_id\":\"1486680242226598130\",\"id\":\"705745250815311942\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , T.andThen
                            100
                            (\data ->
                                case
                                    List.filter
                                        (\request ->
                                            case ( request.url, E2EHelper.decodeCustomRequest request ) of
                                                ( "http://localhost:3000/file/internal/custom-request", Just customRequest ) ->
                                                    (customRequest.url == "https://discord.com/api/v9/channels/705745250815311942/thread-members/@me")
                                                        && (customRequest.method == "PUT")

                                                _ ->
                                                    False
                                        )
                                        data.httpRequests
                                of
                                    [ _ ] ->
                                        [ T.websocketSendString
                                            100
                                            connection
                                            "{\"t\":\"MESSAGE_CREATE\",\"s\":9,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T10:56:31.678000+00:00\",\"position\":0,\"pinned\":false,\"nonce\":\"1486680244629798912\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486680245363802275\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"First message inside thread\",\"components\":[],\"channel_type\":11,\"channel_id\":\"705745250815311942\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                                        , user.checkView
                                            100
                                            (Test.Html.Query.has
                                                [ Test.Html.Selector.exactText "Thread start message"
                                                , Test.Html.Selector.exactText "First message inside thread"
                                                ]
                                            )
                                        ]

                                    _ ->
                                        [ T.checkBackend 100 (\_ -> Err "Didn't join thread") ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Unlinked Discord user starts stand-alone thread"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\user ->
                [ user.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1486698771915083887\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698771915083887\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread title\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_UPDATE\",\"s\":5,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1486698771915083887\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698771915083887\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread title\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"s\":6,\"op\":0,\"d\":{\"user_id\":\"161098476632014848\",\"target_id\":\"1486698771915083887\",\"id\":\"1486698771915083888\",\"changes\":[{\"new_value\":\"Thread title\",\"key\":\"name\"},{\"new_value\":11,\"key\":\"type\"},{\"new_value\":false,\"key\":\"archived\"},{\"new_value\":false,\"key\":\"locked\"},{\"new_value\":4320,\"key\":\"auto_archive_duration\"},{\"new_value\":0,\"key\":\"rate_limit_per_user\"},{\"new_value\":0,\"key\":\"flags\"}],\"action_type\":110,\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_MEMBERS_UPDATE\",\"s\":7,\"op\":0,\"d\":{\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"id\":\"1486698771915083887\",\"added_members\":[{\"user_id\":\"184437096813953035\",\"presence\":{\"user\":{\"username\":\"at28727\",\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"discriminator\":\"0\",\"clan\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"status\":\"online\",\"processed_at_timestamp\":0,\"game\":null,\"client_status\":{\"web\":\"online\"},\"activities\":[]},\"muted\":false,\"mute_config\":null,\"member\":{\"user\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"display_name\":\"AT2\",\"discriminator\":\"0\",\"collectibles\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2025-10-11T19:44:51.312000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"join_timestamp\":\"2026-03-26T12:10:09.250111+00:00\",\"id\":\"1486698771915083887\",\"flags\":1}],\"guild_id\":\"705745250815311942\"}}"
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Thread title" ])
                        , T.andThen
                            100
                            (\data ->
                                case
                                    List.filter
                                        (\request ->
                                            case ( request.url, E2EHelper.decodeCustomRequest request ) of
                                                ( "http://localhost:3000/file/internal/custom-request", Just customRequest ) ->
                                                    (customRequest.url == "https://discord.com/api/v9/channels/1486698771915083887/thread-members/@me")
                                                        && (customRequest.method == "PUT")

                                                _ ->
                                                    False
                                        )
                                        data.httpRequests
                                of
                                    [ _ ] ->
                                        [ T.websocketSendString
                                            100
                                            connection
                                            "{\"t\":\"THREAD_CREATE\",\"s\":8,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-03-26T12:10:08.752000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"name\":\"Thread title\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"member\":{\"user_id\":\"184437096813953035\",\"muted\":false,\"mute_config\":null,\"join_timestamp\":\"2026-03-26T12:10:09.250111+00:00\",\"id\":\"1486698771915083887\",\"flags\":1},\"last_message_id\":null,\"id\":\"1486698771915083887\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                                        , T.websocketSendString
                                            100
                                            connection
                                            "{\"t\":\"MESSAGE_CREATE\",\"s\":9,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:09.497000+00:00\",\"position\":0,\"pinned\":false,\"nonce\":\"1486698774058237952\",\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698775039967375\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread message\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1486698771915083887\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                                        , user.checkView
                                            100
                                            (Test.Html.Query.has
                                                [ Test.Html.Selector.exactText "Thread title"
                                                , Test.Html.Selector.exactText "Thread message"
                                                ]
                                            )
                                        ]

                                    _ ->
                                        [ T.checkBackend 100 (\_ -> Err "Didn't join thread") ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord guild typing indicator"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.exactText "at0232 is typing..." ]
                            )
                        , T.websocketSendString
                            100
                            connection
                            ("{\"t\":\"TYPING_START\",\"s\":3,\"op\":0,\"d\":{\"channel_id\":\"1072828564317159465\",\"guild_id\":\"705745250815311942\",\"user_id\":\"161098476632014848\",\"timestamp\":"
                                ++ String.fromInt (Time.posixToMillis (Duration.addTo E2EHelper.startTime (Duration.seconds 3)))
                                ++ "}}"
                            )
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText "at0232 is typing..." ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Handle new sticker in guild message"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ T.websocketSendString
                            100
                            connection
                            """{"t":"MESSAGE_CREATE","s":521,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-14T04:41:03.112000+00:00","sticker_items":[{"name":"Yippee","id":"1490556070756618301","format_type":1}],"pinned":false,"nonce":"1493471122245550080","mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":["1039567586788122624","1113304630558986240","910335245230944266","686309065940533259","686292987625472082","639296395513430037"],"premium_since":"2022-09-10T14:38:28.084000+00:00","pending":false,"nick":"yargle's gargle marble","mute":false,"joined_at":"2020-03-08T20:30:03.582000+00:00","flags":0,"display_name_styles":{"font_id":4,"effect_id":1,"colors":[]},"deaf":false,"communication_disabled_until":null,"banner":"0aba747031ece851b97166a093d1c509","avatar":"dc78d57d93da1b00fbf15a005821ffa5"},"id":"1493471123155714198","flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"puncharoonie","public_flags":0,"primary_guild":{"tag":"BoNY","identity_guild_id":"821802567876083743","identity_enabled":true,"badge":"4ef966b9bdd3ca7155e184e893314cd6"},"id":"313112240758718464","global_name":"puncharoonie","display_name_styles":{"font_id":7,"effect_id":5,"colors":[1027403]},"discriminator":"0","collectibles":{"nameplate":{"sku_id":"1417311919429128312","palette":"berry","label":"COLLECTIBLES_NAMEPLATE_BONANZA_BERRY_BUNNY_NP_A11Y","expires_at":null,"asset":"nameplates/nameplate_bonanza/berry_bunny/"}},"clan":{"tag":"BoNY","identity_guild_id":"821802567876083743","identity_enabled":true,"badge":"4ef966b9bdd3ca7155e184e893314cd6"},"avatar_decoration_data":{"sku_id":"1354894010522800158","expires_at":null,"asset":"a_b70f0a0cecf3097eae17a8f7d8c659a8"},"avatar":"ae79bf23d7d379b2465eadc6994a2583"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute
                                    (Html.Attributes.src
                                        "http://localhost:3000/file/2/https://media.discordapp.net/stickers/1490556070756618301.png?size=480&quality=lossless"
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Handle new sticker in DM message"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")
                , E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ T.websocketSendString
                            100
                            connection
                            """{"t":"MESSAGE_CREATE","s":521,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-14T04:41:03.112000+00:00","sticker_items":[{"name":"Yippee","id":"1490556070756618301","format_type":1}],"pinned":false,"nonce":"1493471122245550080","mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":["1039567586788122624","1113304630558986240","910335245230944266","686309065940533259","686292987625472082","639296395513430037"],"premium_since":"2022-09-10T14:38:28.084000+00:00","pending":false,"nick":"yargle's gargle marble","mute":false,"joined_at":"2020-03-08T20:30:03.582000+00:00","flags":0,"display_name_styles":{"font_id":4,"effect_id":1,"colors":[]},"deaf":false,"communication_disabled_until":null,"banner":"0aba747031ece851b97166a093d1c509","avatar":"dc78d57d93da1b00fbf15a005821ffa5"},"id":"1493471123155714198","flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1472236476401057854","author":{"username":"purplelite","public_flags":0,"primary_guild":{"tag":"BoNY","identity_guild_id":"821802567876083743","identity_enabled":true,"badge":"4ef966b9bdd3ca7155e184e893314cd6"},"id":"137748026084163584","global_name":"purplelite","display_name_styles":{"font_id":7,"effect_id":5,"colors":[1027403]},"discriminator":"0","collectibles":{"nameplate":{"sku_id":"1417311919429128312","palette":"berry","label":"COLLECTIBLES_NAMEPLATE_BONANZA_BERRY_BUNNY_NP_A11Y","expires_at":null,"asset":"nameplates/nameplate_bonanza/berry_bunny/"}},"clan":{"tag":"BoNY","identity_guild_id":"821802567876083743","identity_enabled":true,"badge":"4ef966b9bdd3ca7155e184e893314cd6"},"avatar_decoration_data":{"sku_id":"1354894010522800158","expires_at":null,"asset":"a_b70f0a0cecf3097eae17a8f7d8c659a8"},"avatar":"ae79bf23d7d379b2465eadc6994a2583"},"attachments":[]}}"""
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute
                                    (Html.Attributes.src
                                        "http://localhost:3000/file/2/https://media.discordapp.net/stickers/1490556070756618301.png?size=480&quality=lossless"
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Two linked Discord accounts in same guild produce single message"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.linkSecondDiscordAccount
                    E2EHelper.sessionId0
                    discordOp0Ready
                    discordOp0ReadySupplemental
                , T.checkState
                    100
                    (\data ->
                        case SeqDict.get E2EHelper.botTestGuild data.backend.discordGuilds of
                            Just guild ->
                                let
                                    memberIds : List (Discord.Id Discord.UserId)
                                    memberIds =
                                        MembersAndOwner.membersAndOwner guild.membersAndOwner
                                in
                                if List.member E2EHelper.currentDiscordUserId memberIds && List.member E2EHelper.secondDiscordUserId memberIds then
                                    Ok ()

                                else
                                    Err "Backend should have both linked Discord users as members of the guild after the second link"

                            Nothing ->
                                Err "Backend doesn't have the Discord guild"
                    )
                , admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , T.collapsableGroup
                    "First message"
                    [ E2EHelper.writeMessage admin 100 "Hello from at-chat with two linked accounts"
                    , T.andThen
                        200
                        (\data ->
                            let
                                messageEvent : String
                                messageEvent =
                                    """{"t":"MESSAGE_CREATE","s":42,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:00:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"123456789012345678","flags":0,"embeds":[],"edited_timestamp":null,"content":"Hello from at-chat with two linked accounts","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                            in
                            case
                                ( E2EHelper.websocketByDiscordToken "legit-token" data
                                , E2EHelper.websocketByDiscordToken E2EHelper.secondDiscordToken data
                                )
                            of
                                ( Just ( firstConnection, _ ), Just ( secondConnection, _ ) ) ->
                                    [ T.websocketSendString 100 firstConnection messageEvent
                                    , T.websocketSendString 100 secondConnection messageEvent
                                    ]

                                _ ->
                                    [ T.checkState 0 (\_ -> Err "Couldn't find both Discord websocket connections") ]
                        )
                    , T.checkState
                        200
                        (\data ->
                            case SeqDict.get E2EHelper.botTestGuild data.backend.discordGuilds of
                                Just guild ->
                                    case SeqDict.get E2EHelper.botTestGuild_ChannelA guild.channels of
                                        Just channel ->
                                            case IdArray.length channel.messages of
                                                1 ->
                                                    Ok ()

                                                count ->
                                                    Err ("Expected the guild's channel to contain exactly one message but got " ++ String.fromInt count)

                                        Nothing ->
                                            Err "Channel not found in guild"

                                Nothing ->
                                    Err "Discord guild not found"
                        )
                    , admin.checkView
                        100
                        (\html ->
                            Test.Html.Query.findAll [ Test.Html.Selector.exactText "Hello from at-chat with two linked accounts" ] html
                                |> Test.Html.Query.count (Expect.equal 1)
                        )
                    ]
                , T.collapsableGroup
                    "Second message"
                    [ T.andThen
                        200
                        (\data ->
                            let
                                messageEvent : String
                                messageEvent =
                                    """{"t":"MESSAGE_CREATE","s":42,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:00:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1234567890","flags":0,"embeds":[],"edited_timestamp":null,"content":"This is message 2","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                            in
                            case
                                ( E2EHelper.websocketByDiscordToken "legit-token" data
                                , E2EHelper.websocketByDiscordToken E2EHelper.secondDiscordToken data
                                )
                            of
                                ( Just ( firstConnection, _ ), Just ( secondConnection, _ ) ) ->
                                    [ T.websocketSendString 100 firstConnection messageEvent
                                    , T.websocketSendString 100 secondConnection messageEvent
                                    ]

                                _ ->
                                    [ T.checkState 0 (\_ -> Err "Couldn't find both Discord websocket connections") ]
                        )
                    , T.checkState
                        200
                        (\data ->
                            case SeqDict.get E2EHelper.botTestGuild data.backend.discordGuilds of
                                Just guild ->
                                    case SeqDict.get E2EHelper.botTestGuild_ChannelA guild.channels of
                                        Just channel ->
                                            case IdArray.length channel.messages of
                                                2 ->
                                                    Ok ()

                                                count ->
                                                    Err ("Expected the guild's channel to contain exactly two messages but got " ++ String.fromInt count)

                                        Nothing ->
                                            Err "Channel not found in guild"

                                Nothing ->
                                    Err "Discord guild not found"
                        )
                    , admin.checkView
                        100
                        (\html ->
                            Test.Html.Query.findAll [ Test.Html.Selector.exactText "This is message 2" ] html
                                |> Test.Html.Query.count (Expect.equal 1)
                        )
                    ]
                ]
            )
        ]
    , E2EHelper.startTest
        "No Discord guild push notification while viewing the channel"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , E2EHelper.enableNotifications False admin
                        , E2EHelper.checkNotification "Success!" "Push notifications enabled"

                        -- The admin is viewing the Discord guild channel, so a message mentioning them should NOT push.
                        , discordGuildMessage connection "<@184437096813953035> while viewing"
                        , E2EHelper.checkNoNotification "@at28727 while viewing"

                        -- Navigate the admin away from the channel.
                        , admin.click 100 (Dom.id "guildIcon_showFriends")

                        -- Positive control: while the admin isn't viewing the channel a mention should push.
                        , discordGuildMessage connection "<@184437096813953035> while away"
                        , E2EHelper.checkNotification "at0232" "@at28727 while away"
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord guild message push notification has correct title and body"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ E2EHelper.enableNotifications False admin
                        , E2EHelper.checkNotification "Success!" "Push notifications enabled"

                        -- The admin isn't viewing the Discord guild channel, so a message from
                        -- at0232 mentioning them pushes a notification. The title is the Discord
                        -- username of the sender and the body is the message text.
                        , discordGuildMessage connection "<@184437096813953035> check the notification"
                        , E2EHelper.checkNotification "at0232" "@at28727 check the notification"
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "No Discord DM push notification while viewing the channel"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ E2EHelper.enableNotifications False admin
                        , E2EHelper.checkNotification "Success!" "Push notifications enabled"

                        -- Positive control: while the admin isn't viewing the DM a message should push.
                        , discordDmMessage connection "Discord DM while away"
                        , E2EHelper.checkNotification "capysuit" "Discord DM while away"

                        -- Open (and therefore view) the Discord DM channel.
                        , admin.click 100 (Dom.id "guildIcon_showFriends")
                        , admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")

                        -- The admin is viewing the DM the message arrived in, so no push notification should be sent.
                        , discordDmMessage connection "Discord DM while viewing"
                        , E2EHelper.checkNoNotification "Discord DM while viewing"
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Draw on top of messages in Discord DM"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")
                        , discordDmMessage connection "Draw on this Discord DM message!"
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Draw on this Discord DM message!" ])

                        -- Open the drawing tab and check that the instructions show up
                        , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "Click on a profile image" ])
                        , T.andThen
                            100
                            (\data ->
                                case lastDiscordDmMessage data.backend of
                                    Just ( messageId, _ ) ->
                                        [ -- Hovering the message reveals its profile image anchor: the anchor
                                          -- is only rendered (and clickable) while the message is hovered and
                                          -- the drawing tab is picking an anchor.
                                          admin.mouseEnter 100 (Dom.id ("guild_message_" ++ Id.toString messageId)) ( 10, 10 ) []

                                        -- Click the message's profile image to use it as the drawing anchor
                                        , admin.custom
                                            100
                                            (Drawing.profileImageAnchorId messageId)
                                            "click"
                                            (E2EHelper.drawingAnchorClick 30 25)
                                        , admin.checkView
                                            100
                                            (Test.Html.Query.has [ Test.Html.Selector.text "Draw with the mouse" ])
                                        , E2EHelper.drawZigzagStroke admin
                                        , admin.checkView 100 (E2EHelper.expectPolylineCount 1)

                                        -- The stroke is stored on the backend in the Discord DM channel
                                        , T.checkState
                                            100
                                            (\data2 ->
                                                case lastDiscordDmMessage data2.backend of
                                                    Just ( _, message ) ->
                                                        if List.length (Message.drawing Drawing.UserIconAnchor message).finished == 1 then
                                                            Ok ()

                                                        else
                                                            Err "Expected the message to contain exactly one finished stroke"

                                                    Nothing ->
                                                        Err "Message not found on the backend"
                                            )

                                        -- Pressing the pencil tab again closes the drawing tab
                                        , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                                        , admin.checkView
                                            100
                                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "Draw with the mouse" ])
                                        ]

                                    Nothing ->
                                        [ T.checkState 0 (\_ -> Err "No message found to draw on") ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord DM channel description"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")
                        , discordDmMessage connection "Hello!"

                        -- Clicking the channel name in the header opens the channel description tab
                        , admin.click 100 (Dom.id "guild_openDescription")
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "A Discord DM channel for you and" ])
                        , admin.snapshotView 100 { name = "Discord DM channel description" }

                        -- Clicking the channel name again closes the tab
                        , admin.click 100 (Dom.id "guild_openDescription")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "A Discord DM channel for you and" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord DM notification shows red icon in guild column"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ -- The admin is on the friends page and isn't viewing the Discord DM, so no
                          -- notification icon is shown in the guild column yet.
                          admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.id "guildsColumn_openDiscordDm_1472236476401057854" ]
                            )
                        , E2EHelper.tallSnapshot admin 100 { name = "Discord DM no notification icon" }

                        -- A Discord DM arrives while the admin isn't viewing it.
                        , discordDmMessage connection "Check out this Discord DM!"
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Check out this Discord DM!" ])

                        -- A red notification icon for the Discord DM now appears in the guild column.
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.id "guildsColumn_openDiscordDm_1472236476401057854" ]
                            )

                        -- The notification circle also appears on the DM in the DM channel column.
                        , friendLabelHasNotificationCircle admin "1472236476401057854" "1"
                        , E2EHelper.tallSnapshot admin 100 { name = "Discord DM notification icon in guild column" }

                        -- Opening the Discord DM marks it as read, removing the notification icon
                        -- from both the guild column and the DM channel column.
                        , admin.click 100 (Dom.id "guildsColumn_openDiscordDm_1472236476401057854")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.id "guildsColumn_openDiscordDm_1472236476401057854" ]
                            )
                        , friendLabelHasNoNotificationCircle admin "1472236476401057854" "1"
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord group DM notification shows red icon in guild column"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ -- A new Discord group DM (the linked account plus two other users) is created.
                          T.websocketSendString 100 connection discordGroupDmChannelCreate

                        -- The admin isn't viewing the group DM, and it has no messages, so no
                        -- notification icon is shown in the guild column yet.
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.id "guildsColumn_openDiscordDm_1500000000000000099" ]
                            )

                        -- A message arrives in the group DM while the admin isn't viewing it.
                        , discordGroupDmMessage connection "Hello everyone in the group!"
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Hello everyone in the group!" ])

                        -- A red notification icon for the group DM now appears in the guild column.
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.id "guildsColumn_openDiscordDm_1500000000000000099" ]
                            )

                        -- The notification circle also appears on the group DM in the DM channel column.
                        , friendLabelHasNotificationCircle admin "1500000000000000099" "1"
                        , E2EHelper.tallSnapshot admin 100 { name = "Discord group DM notification icon in guild column" }

                        -- Opening the group DM marks it as read, removing the notification icon
                        -- from both the guild column and the DM channel column.
                        , admin.click 100 (Dom.id "guildsColumn_openDiscordDm_1500000000000000099")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.id "guildsColumn_openDiscordDm_1500000000000000099" ]
                            )
                        , friendLabelHasNoNotificationCircle admin "1500000000000000099" "1"
                        , discordGroupDmMessage connection "Second message"
                        , E2EHelper.tallSnapshot admin 100 { name = "Viewing Discord group DM" }
                        , admin.click 100 (Dom.id "guildIcon_showFriends")
                        , friendLabelHasNoNotificationCircle admin "1500000000000000099" "1"
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Private Discord channel is hidden from a user without access"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ -- The admin's linked Discord account creates a private channel that only it
                  -- can view (@everyone is denied View Channel, the admin's account is allowed).
                  E2EHelper.andThenWebsocket
                    (\connection _ ->
                        [ T.websocketSendString 100 connection privateDiscordChannelCreateEvent ]
                    )
                , -- Sanity check: the backend stored the private channel with its overwrites.
                  T.checkState
                    100
                    (\data ->
                        case SeqDict.get E2EHelper.botTestGuild data.backend.discordGuilds of
                            Just guild ->
                                case SeqDict.get privateDiscordChannelId guild.channels of
                                    Just channel ->
                                        if List.isEmpty channel.permissionOverwrites then
                                            Err "The private channel was created without permission overwrites"

                                        else
                                            Ok ()

                                    Nothing ->
                                        Err "The backend didn't create the private channel"

                            Nothing ->
                                Err "The backend doesn't have the Bot Test guild"
                    )
                , -- A second, distinct at-chat user links a different Discord account (555...)
                  -- which is a member of the guild but has no access to the private channel.
                  E2EHelper.linkDiscordAndLoginSecondUser
                    E2EHelper.sessionId1
                    "Second User"
                    E2EHelper.userEmail
                    discordOp0Ready
                    discordOp0ReadySupplemental
                    (\_ -> [])
                , -- Sanity check: the second user's Discord account is now a guild member on the backend.
                  T.checkState
                    100
                    (\data ->
                        case SeqDict.get E2EHelper.botTestGuild data.backend.discordGuilds of
                            Just backendGuild ->
                                if List.member E2EHelper.secondDiscordUserId (MembersAndOwner.membersAndOwner backendGuild.membersAndOwner) then
                                    Ok ()

                                else
                                    Err "The second user's Discord account never became a member of the Bot Test guild, so the private channel scenario can't be verified"

                            Nothing ->
                                Err "The backend doesn't have the Bot Test guild"
                    )
                , -- Reconnect the second user in a fresh tab so their initial load delivers the guild
                  -- and its channels. A user without access to the private channel should not receive
                  -- it, so it should be absent from their frontend.
                  T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    "/"
                    E2EHelper.desktopWindow
                    (\userB ->
                        [ T.andThen
                            10
                            (\data -> [ userB.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , T.checkState
                            500
                            (\data ->
                                case SeqDict.get userB.clientId data.frontends |> Maybe.map Audio.userModel of
                                    Just (Types.Loaded loaded) ->
                                        case loaded.loginStatus of
                                            Types.LoggedIn loggedIn ->
                                                let
                                                    local : LocalState.LocalState
                                                    local =
                                                        Local.model loggedIn.localState
                                                in
                                                case SeqDict.get E2EHelper.botTestGuild local.discordGuilds of
                                                    Just guild ->
                                                        if SeqDict.member privateDiscordChannelId guild.channels then
                                                            Err "The second user, whose Discord account has no access to the private channel, can still see the private channel in their guild"

                                                        else
                                                            Ok ()

                                                    Nothing ->
                                                        Err "The Bot Test guild wasn't delivered to the second user's frontend, so the private channel scenario can't be verified"

                                            _ ->
                                                Err "Expected the second user to be logged in"

                                    _ ->
                                        Err "Expected the second user's frontend to be loaded"
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord users are loaded based on the guild being viewed plus DM channels"
        E2EHelper.startTime
        normalConfig
        [ -- (1) Connecting while not viewing any Discord guild. Only the Discord users from the DM
          -- channels the linked account belongs to are loaded: kess shares a DM channel and is
          -- loaded, while AT (only a member of the Bot Test guild, with no shared DM channel) is
          -- not, and neither is TesterBot (neither a guild member nor a DM channel participant).
          E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.checkModel 100 (checkDiscordUserLoaded "DM channel user kess" True dmChannelOnlyDiscordUserId)
                , admin.checkModel 100 (checkDiscordUserLoaded "Discord guild-only member AT" False guildOnlyDiscordUserId)
                , admin.checkModel 100 (checkDiscordUserLoaded "Unrelated Discord user TesterBot" False unrelatedDiscordUserId)
                ]
            )

        -- (2) Connecting (a second client on the same session) while viewing the Bot Test guild. The
        -- members of the viewed guild are loaded as part of the initial data load, in addition to
        -- the DM channel users: AT (a Bot Test member) is now loaded alongside kess (a DM channel
        -- user). A Discord user that is neither a member of the Bot Test guild nor part of a shared
        -- DM channel (TesterBot) is still not loaded, i.e. only the viewed guild's members get
        -- loaded.
        , T.connectFrontend
            100
            E2EHelper.sessionId0
            (Route.encode
                (Route.DiscordGuildRoute
                    { currentDiscordUserId = E2EHelper.currentDiscordUserId
                    , guildId = E2EHelper.botTestGuild
                    , channelRoute =
                        Route.DiscordChannel_ChannelRoute
                            E2EHelper.botTestGuild_ChannelA
                            (Route.NoThreadWithFriends Nothing Route.ShowMembersTab)
                            Nothing
                    }
                )
            )
            E2EHelper.desktopWindow
            (\viewer ->
                [ T.andThen
                    10
                    (\data -> [ viewer.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                , viewer.checkModel 200 (checkDiscordUserLoaded "Discord guild member AT" True guildOnlyDiscordUserId)
                , viewer.checkModel 100 (checkDiscordUserLoaded "DM channel user kess" True dmChannelOnlyDiscordUserId)
                , viewer.checkModel 100 (checkDiscordUserLoaded "Unrelated Discord user TesterBot" False unrelatedDiscordUserId)
                ]
            )
        ]

    --, startTest
    --    "Discord guild thread typing indicator"
    --    startTime
    --    normalConfig
    --    [ linkDiscordAndLogin
    --        sessionId0
    --        (PersonName.toString Backend.adminUser.name)
    --        adminEmail
    --        False
    --        discordOp0Ready
    --        discordOp0ReadySupplemental
    --        (\admin ->
    --            [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
    --            , andThenWebsocket
    --                (\connection _ ->
    --                    [ T.websocketSendString
    --                        100
    --                        connection
    --                        "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1486698771915083887\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698771915083887\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread starter\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
    --                    , T.websocketSendString
    --                        100
    --                        connection
    --                        "{\"t\":\"MESSAGE_UPDATE\",\"s\":5,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1486698771915083887\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1486698771915083887\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread starter\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
    --                    , T.websocketSendString
    --                        100
    --                        connection
    --                        "{\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"s\":6,\"op\":0,\"d\":{\"user_id\":\"161098476632014848\",\"target_id\":\"1486698771915083887\",\"id\":\"1486698771915083888\",\"changes\":[{\"new_value\":\"Thread starter\",\"key\":\"name\"},{\"new_value\":11,\"key\":\"type\"},{\"new_value\":false,\"key\":\"archived\"},{\"new_value\":false,\"key\":\"locked\"},{\"new_value\":4320,\"key\":\"auto_archive_duration\"},{\"new_value\":0,\"key\":\"rate_limit_per_user\"},{\"new_value\":0,\"key\":\"flags\"}],\"action_type\":110,\"guild_id\":\"705745250815311942\"}}"
    --                    , T.websocketSendString
    --                        100
    --                        connection
    --                        "{\"t\":\"THREAD_MEMBERS_UPDATE\",\"s\":7,\"op\":0,\"d\":{\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"id\":\"1486698771915083887\",\"added_members\":[{\"user_id\":\"184437096813953035\",\"presence\":{\"user\":{\"username\":\"at28727\",\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"discriminator\":\"0\",\"clan\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"status\":\"online\",\"processed_at_timestamp\":0,\"game\":null,\"client_status\":{\"web\":\"online\"},\"activities\":[]},\"muted\":false,\"mute_config\":null,\"member\":{\"user\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"display_name\":\"AT2\",\"discriminator\":\"0\",\"collectibles\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2025-10-11T19:44:51.312000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"join_timestamp\":\"2026-03-26T12:10:09.250111+00:00\",\"id\":\"1486698771915083887\",\"flags\":1}],\"guild_id\":\"705745250815311942\"}}"
    --                    , T.andThen
    --                        100
    --                        (\data ->
    --                            case
    --                                List.filter
    --                                    (\request ->
    --                                        case ( request.url, decodeCustomRequest request ) of
    --                                            ( "http://localhost:3000/file/internal/custom-request", Just ( method, url ) ) ->
    --                                                (url == "https://discord.com/api/v9/channels/1486698771915083887/thread-members/@me")
    --                                                    && (method == "PUT")
    --
    --                                            _ ->
    --                                                False
    --                                    )
    --                                    data.httpRequests
    --                            of
    --                                [ _ ] ->
    --                                    [ T.websocketSendString
    --                                        100
    --                                        connection
    --                                        "{\"t\":\"THREAD_CREATE\",\"s\":8,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-03-26T12:10:08.752000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"name\":\"Thread starter\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"member\":{\"user_id\":\"184437096813953035\",\"muted\":false,\"mute_config\":null,\"join_timestamp\":\"2026-03-26T12:10:09.250111+00:00\",\"id\":\"1486698771915083887\",\"flags\":1},\"last_message_id\":null,\"id\":\"1486698771915083887\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
    --                                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Thread starter" ])
    --
    --                                    -- Click on thread to open it
    --                                    , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
    --
    --                                    -- No typing indicator yet
    --                                    , admin.checkView
    --                                        100
    --                                        (Test.Html.Query.hasNot
    --                                            [ Test.Html.Selector.exactText "at0232 is typing..." ]
    --                                        )
    --
    --                                    -- Send typing start in the thread channel
    --                                    , T.websocketSendString 100 connection "{\"t\":\"TYPING_START\",\"s\":9,\"op\":0,\"d\":{\"channel_id\":\"1486698771915083887\",\"guild_id\":\"705745250815311942\",\"user_id\":\"161098476632014848\",\"timestamp\":1}}"
    --                                    , admin.checkView
    --                                        100
    --                                        (Test.Html.Query.has
    --                                            [ Test.Html.Selector.exactText "at0232 is typing..." ]
    --                                        )
    --                                    ]
    --
    --                                _ ->
    --                                    [ T.checkBackend 100 (\_ -> Err "Didn't join thread") ]
    --                        )
    --                    ]
    --                )
    --            ]
    --        )
    --    ]
    ]


{-| A unique value derived from the current test time. Used for the gateway sequence
number and message id so that each `MESSAGE_CREATE` event is unique without the caller
having to thread a counter through the test (the test clock always advances between
sends).
-}
uniqueFromTime : Time.Posix -> String
uniqueFromTime time =
    Time.posixToMillis time |> String.fromInt


{-| Send a Discord guild `MESSAGE_CREATE` gateway event for the Bot Test guild's
channel A, sent by `at0232` (a user other than the linked admin account). The message
timestamp is the current test time and the sequence number/message id are derived from
it. `content` is the raw Discord message content (so a mention is written as
`<@userId>`).
-}
discordGuildMessage : Websocket.Connection -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
discordGuildMessage connection content =
    T.andThen
        100
        (\data ->
            let
                unique : String
                unique =
                    uniqueFromTime data.time
            in
            [ T.websocketSendString
                0
                connection
                ("{\"t\":\"MESSAGE_CREATE\",\"s\":" ++ unique ++ ",\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"" ++ Iso8601.fromTime data.time ++ "\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"" ++ unique ++ "\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"" ++ content ++ "\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"discriminator\":\"0\",\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}")
            ]
        )


{-| Send a Discord DM `MESSAGE_CREATE` gateway event (no `guild_id`) for the private
channel the linked admin shares with user `137748026084163584`, sent by that other
user. The message timestamp is the current test time and the sequence number/message
id are derived from it.
-}
discordDmMessage : Websocket.Connection -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
discordDmMessage connection content =
    T.andThen
        100
        (\data ->
            let
                unique : String
                unique =
                    uniqueFromTime data.time
            in
            [ T.websocketSendString
                0
                connection
                ("{\"t\":\"MESSAGE_CREATE\",\"s\":" ++ unique ++ ",\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"" ++ Iso8601.fromTime data.time ++ "\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"id\":\"" ++ unique ++ "\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"" ++ content ++ "\",\"components\":[],\"channel_type\":1,\"channel_id\":\"1472236476401057854\",\"author\":{\"username\":\"capysuit\",\"public_flags\":0,\"id\":\"137748026084163584\",\"global_name\":\"gio\",\"discriminator\":\"0\",\"avatar\":\"7d2709668c67727f98ba40ff62611e78\"},\"attachments\":[]}}")
            ]
        )


{-| A `CHANNEL_CREATE` gateway event for a Discord group DM (channel id
`1500000000000000099`) whose members are the linked account (`184437096813953035`)
plus two other Discord users (`at0232` and `kess`).
-}
discordGroupDmChannelCreate : String
discordGroupDmChannelCreate =
    "{\"t\":\"CHANNEL_CREATE\",\"s\":410,\"op\":0,\"d\":{\"type\":3,\"id\":\"1500000000000000099\",\"last_message_id\":null,\"recipients\":[{\"username\":\"at28727\",\"id\":\"184437096813953035\",\"discriminator\":\"0\",\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},{\"username\":\"at0232\",\"id\":\"161098476632014848\",\"discriminator\":\"0\",\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},{\"username\":\"kess\",\"id\":\"168547048902098944\",\"discriminator\":\"0\",\"avatar\":null}]}}"


{-| Send a `MESSAGE_CREATE` for the Discord group DM created by
`discordGroupDmChannelCreate`, sent by `at0232`. The message timestamp is the current
test time and the sequence number/message id are derived from it.
-}
discordGroupDmMessage : Websocket.Connection -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
discordGroupDmMessage connection content =
    T.andThen
        100
        (\data ->
            let
                unique : String
                unique =
                    uniqueFromTime data.time
            in
            [ T.websocketSendString
                0
                connection
                ("{\"t\":\"MESSAGE_CREATE\",\"s\":" ++ unique ++ ",\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"" ++ Iso8601.fromTime data.time ++ "\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"id\":\"" ++ unique ++ "\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"" ++ content ++ "\",\"components\":[],\"channel_type\":3,\"channel_id\":\"1500000000000000099\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"discriminator\":\"0\",\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[]}}")
            ]
        )


{-| Assert that the Discord DM/group DM friend label (in the DM channel column) for the
given private channel id shows a notification circle with the given count. The count is
rendered as the badge's `aria-label`.
-}
friendLabelHasNotificationCircle :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
friendLabelHasNotificationCircle user channelId count =
    user.checkView
        100
        (\html ->
            Test.Html.Query.find
                [ Test.Html.Selector.id ("guild_discordFriendLabel_" ++ channelId) ]
                html
                |> Test.Html.Query.has
                    [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" count) ]
        )


{-| Assert that the Discord DM/group DM friend label (in the DM channel column) for the
given private channel id shows no notification circle with the given count.
-}
friendLabelHasNoNotificationCircle :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
friendLabelHasNoNotificationCircle user channelId count =
    user.checkView
        100
        (\html ->
            Test.Html.Query.find
                [ Test.Html.Selector.id ("guild_discordFriendLabel_" ++ channelId) ]
                html
                |> Test.Html.Query.hasNot
                    [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" count) ]
        )


{-| `AT`. A member of the Bot Test guild that does not share a DM channel with the
linked account, so it is only loaded onto the frontend while the Bot Test guild is
being viewed.
-}
guildOnlyDiscordUserId : Discord.Id Discord.UserId
guildOnlyDiscordUserId =
    Unsafe.uint64 "1401255355928936478" |> Discord.idFromUInt64


{-| `kess`. Shares a DM channel with the linked account but is not a member of the Bot
Test guild, so it is loaded as soon as the user connects regardless of which guild (if
any) they are viewing.
-}
dmChannelOnlyDiscordUserId : Discord.Id Discord.UserId
dmChannelOnlyDiscordUserId =
    Unsafe.uint64 "168547048902098944" |> Discord.idFromUInt64


{-| `TesterBot`. Neither a member of the Bot Test guild nor part of a shared DM channel,
so it should never be loaded onto the frontend.
-}
unrelatedDiscordUserId : Discord.Id Discord.UserId
unrelatedDiscordUserId =
    Unsafe.uint64 "304157401937084416" |> Discord.idFromUInt64


{-| Check whether a given Discord user has (or hasn't) been loaded into the set of "other"
Discord users on the frontend. These are the Discord users loaded for the DM channels the
user belongs to plus the members of whatever Discord guild the user is currently viewing.
-}
checkDiscordUserLoaded : String -> Bool -> Discord.Id Discord.UserId -> FrontendModel -> Result String ()
checkDiscordUserLoaded label shouldBeLoaded discordUserId model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    let
                        isLoaded : Bool
                        isLoaded =
                            LinkedAndOtherDiscordUsers.getOtherUser
                                discordUserId
                                (Local.model loggedIn.localState).localUser.discordUsers
                                /= Nothing
                    in
                    if isLoaded == shouldBeLoaded then
                        Ok ()

                    else if shouldBeLoaded then
                        Err (label ++ " should be loaded but wasn't")

                    else
                        Err (label ++ " should not be loaded but was")

                Types.NotLoggedIn _ ->
                    Err (label ++ ": expected the frontend to be logged in")

        Types.Loading _ ->
            Err (label ++ ": expected the frontend to have finished loading")


{-| The Discord DM channel `discordDmMessage` sends messages to.
-}
discordDmChannelId : Discord.Id Discord.PrivateChannelId
discordDmChannelId =
    Unsafe.uint64 "1472236476401057854" |> Discord.idFromUInt64


{-| The most recent message in the Discord DM channel used by `discordDmMessage`.
-}
lastDiscordDmMessage : BackendModel -> Maybe ( Id.Id Id.ChannelMessageId, Message.Message Id.ChannelMessageId (Discord.Id Discord.UserId) )
lastDiscordDmMessage backend =
    case SeqDict.get discordDmChannelId backend.discordDmChannels of
        Just channel ->
            case IdArray.last channel.messages of
                Just message ->
                    Just ( Id.fromInt (IdArray.length channel.messages - 1), message )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing
