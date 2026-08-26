module E2EDiscord exposing (discordTests)

import Array
import Audio
import Backend
import Codec
import CustomEmoji exposing (CustomEmojiData)
import Discord
import DiscordUserData
import Drawing
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Websocket as Websocket
import Emoji exposing (EmojiOrCustomEmoji(..))
import Expect
import GuildIcon
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), DiscordGuildOrDmId(..), GuildOrDmId(..), ThreadRoute(..), ThreadRouteWithMaybeMessage(..))
import IdArray
import Iso8601
import Json.Decode
import Json.Encode
import LinkedAndOtherDiscordUsers
import List.Extra
import List.Nonempty
import Local exposing (ChangeId(..))
import LocalState
import MembersAndOwner
import Message
import MessageArray
import MessageInput
import NonemptyDict
import NonemptySet
import Pages.Admin
import Pages.Guild
import PersonName
import RichText
import Route exposing (ShowChannelSettings(..))
import SeqDict
import SeqSet
import Sticker
import String.Nonempty exposing (NonemptyString(..))
import Test.Html.Query
import Test.Html.Selector
import Time
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, LocalChange(..), ToBackend(..), ToFrontend)
import Unsafe
import User
import UserSession exposing (SetViewing(..))


{-| Runs the given function against the admin frontend's LocalState, surfacing a
descriptive error if the admin isn't loaded/logged in.
-}
withAdminLocalState :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Data FrontendModel E2EHelper.BackendModel2
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
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> (Int -> Bool)
    -> T.Data FrontendModel E2EHelper.BackendModel2
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
                                ++ String.fromInt (MessageArray.length dmChannel.messages)
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


{-| A Discord MESSAGE\_REACTION\_ADD adding the `reactemoji` custom emoji to the message
the reaction test creates, from whichever user id it's given.
-}
reactEmojiReactionAdd : String -> String
reactEmojiReactionAdd userId =
    "{\"t\":\"MESSAGE_REACTION_ADD\",\"s\":5,\"op\":0,\"d\":{\"user_id\":\""
        ++ userId
        ++ "\",\"message_id\":\"1500000000000000001\",\"emoji\":{\"id\":\"888159336168300600\",\"name\":\"reactemoji\"},\"channel_id\":\"1072828564317159465\",\"guild_id\":\"705745250815311942\",\"burst\":false}}"


{-| Discord user ids for the stand-in users that pile reactions onto that message. A
reaction only records the id of whoever reacted, so nobody has to exist for this.
-}
reactingUserId : Int -> String
reactingUserId index =
    "90000000000000" ++ String.padLeft 4 '0' (String.fromInt index)


{-| A Discord MESSAGE\_REACTION\_ADD adding a unicode emoji reaction to a message in the
Bot Test guild. A message written in a thread is reacted to the same way, with the thread's
id in the channel\_id field, which is how Discord addresses it.
-}
unicodeReactionAdd : { channelId : String, messageId : String, emoji : String, userId : String } -> String
unicodeReactionAdd reaction =
    "{\"t\":\"MESSAGE_REACTION_ADD\",\"s\":6,\"op\":0,\"d\":{\"user_id\":\""
        ++ reaction.userId
        ++ "\",\"message_id\":\""
        ++ reaction.messageId
        ++ "\",\"emoji\":{\"id\":null,\"name\":\""
        ++ reaction.emoji
        ++ "\"},\"channel_id\":\""
        ++ reaction.channelId
        ++ "\",\"guild_id\":\"705745250815311942\",\"burst\":false}}"


{-| Have the admin reload the Bot Test guild's channel A, the same way the button on the
admin page does. Discord answers with E2EHelper.botTestGuildChannelAHistory.
-}
reloadDiscordChannelA :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> ChangeId
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
reloadDiscordChannelA admin changeId =
    admin.sendToBackend
        100
        (LocalModelChangeRequest
            changeId
            (Local_Admin
                (Pages.Admin.StartReloadingDiscordGuildChannel
                    E2EHelper.startTime
                    E2EHelper.currentDiscordUserId
                    E2EHelper.botTestGuild
                    E2EHelper.botTestGuild_ChannelA
                )
            )
        )


{-| Checks how many people the frontend thinks have reacted to that message, so that a
snapshot of the count can't quietly end up being a snapshot of the wrong number.
-}
checkReactingUserCount :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> Int
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkReactingUserCount admin expected =
    T.checkState
        100
        (\data ->
            withAdminLocalState admin
                data
                (\local ->
                    case LocalState.getDiscordGuildAndChannel checkGuildVisibleMessageCountGuildId checkGuildVisibleMessageCountChannelId local of
                        Just ( _, channel ) ->
                            case MessageArray.last channel.messages of
                                Just message ->
                                    case Message.reactionEmojis message |> SeqDict.values of
                                        [ users ] ->
                                            if NonemptySet.size users == expected then
                                                Ok ()

                                            else
                                                Err
                                                    ("Expected "
                                                        ++ String.fromInt expected
                                                        ++ " people to have reacted but the frontend has "
                                                        ++ String.fromInt (NonemptySet.size users)
                                                    )

                                        _ ->
                                            Err "Expected exactly one reaction on the frontend's message"

                                Nothing ->
                                    Err "The frontend's copy of the message is missing"

                        Nothing ->
                            Err "The Discord guild channel is missing from the frontend"
                )
        )


{-| Reads the number of currently visible messages in the bot test guild's channel
(guild 705745250815311942, channel 1072828564317159465) from the admin frontend and
checks it against a predicate.
-}
checkGuildVisibleMessageCount :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> (Int -> Bool)
    -> T.Data FrontendModel E2EHelper.BackendModel2
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
                                ++ String.fromInt (MessageArray.length channel.messages)
                                ++ " message(s). HandleReadyDataStep2 wiped the visible messages of the open guild channel, so they disappear from view."
                            )

                Nothing ->
                    Err "The Discord guild channel is missing from the frontend"
        )


guildEmojisUpdateGuildId : Discord.Id Discord.GuildId
guildEmojisUpdateGuildId =
    Unsafe.uint64 "705745250815311942" |> Discord.idFromUInt64


{-| Reads the names of the custom emojis the admin can use in the bot test guild
(guild 705745250815311942) and checks them against the expected names.
-}
checkGuildCustomEmojis :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> List String
    -> T.Data FrontendModel E2EHelper.BackendModel2
    -> Result String ()
checkGuildCustomEmojis admin expected data =
    withAdminLocalState admin
        data
        (\local ->
            case SeqDict.get guildEmojisUpdateGuildId local.discordGuilds of
                Just guild ->
                    let
                        names : List String
                        names =
                            LocalState.discordGuildAvailableStickersAndCustomEmojis local.localUser guild
                                |> Tuple.first
                                |> SeqSet.toList
                                |> List.filterMap
                                    (\customEmojiId ->
                                        SeqDict.get customEmojiId local.localUser.customEmojis
                                            |> Maybe.map (\customEmoji -> CustomEmoji.emojiNameToString customEmoji.name)
                                    )
                                |> List.sort
                    in
                    if names == List.sort expected then
                        Ok ()

                    else
                        Err
                            ("Expected the bot test guild to have the custom emojis "
                                ++ String.join ", " (List.sort expected)
                                ++ " but it has "
                                ++ String.join ", " names
                            )

                Nothing ->
                    Err "The Discord guild is missing from the frontend"
        )


{-| Checks that the backend sent a resume (op 6) with the given session id and sequence number on
this connection, and that it didn't identify (op 2) instead.
-}
checkResumeSent : { sessionId : String, seq : Int } -> T.WebsocketState -> Result String ()
checkResumeSent expected websocketState =
    let
        sent : List String
        sent =
            Array.toList websocketState.dataSent |> List.map .data

        decodeResume : Json.Decode.Decoder { sessionId : String, seq : Int }
        decodeResume =
            Json.Decode.map2
                (\sessionId seq -> { sessionId = sessionId, seq = seq })
                (Json.Decode.at [ "d", "session_id" ] Json.Decode.string)
                (Json.Decode.at [ "d", "seq" ] Json.Decode.int)
    in
    if List.any E2EHelper.isOp2 (Array.toList websocketState.dataSent) then
        Err "The backend identified with a new session instead of resuming the old one"

    else
        case List.filterMap (\data -> Json.Decode.decodeString decodeResume data |> Result.toMaybe) sent of
            [ resume ] ->
                if resume == expected then
                    Ok ()

                else
                    Err
                        ("Expected a resume with session id "
                            ++ expected.sessionId
                            ++ " and seq "
                            ++ String.fromInt expected.seq
                            ++ " but got session id "
                            ++ resume.sessionId
                            ++ " and seq "
                            ++ String.fromInt resume.seq
                        )

            resumes ->
                Err ("Expected exactly one resume to be sent but " ++ String.fromInt (List.length resumes) ++ " were sent")


discordTests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> String
    -> String
    -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2)
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , -- The guild column mixes at-chat guilds and Discord guilds, so
                          -- Discord ones carry a Discord logo to tell them apart.
                          admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.find
                                    [ Test.Html.Selector.id "guild_openDiscordGuild_705745250815311942" ]
                                    html
                                    |> Test.Html.Query.has
                                        [ Test.Html.Selector.attribute
                                            (Html.Attributes.attribute "aria-label" GuildIcon.discordLabel)
                                        ]
                            )
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        let
                            customEmojiNamed : String -> T.Data FrontendModel E2EHelper.BackendModel2 -> List CustomEmojiData
                            customEmojiNamed name data =
                                SeqDict.values (E2EHelper.unwrapBackend data.backend).customEmojis
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        let
                            customEmojiNamed : String -> T.Data FrontendModel E2EHelper.BackendModel2 -> List CustomEmojiData
                            customEmojiNamed name data =
                                SeqDict.values (E2EHelper.unwrapBackend data.backend).customEmojis
                                    |> List.filter (\customEmoji -> CustomEmoji.emojiNameToString customEmoji.name == name)

                            lastMessageReactions :
                                T.Data FrontendModel E2EHelper.BackendModel2
                                -> Result String (List EmojiOrCustomEmoji)
                            lastMessageReactions data =
                                case SeqDict.get checkGuildVisibleMessageCountGuildId (E2EHelper.unwrapBackend data.backend).discordGuilds of
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
                        , T.websocketSendString 100 connection (reactEmojiReactionAdd "161098476632014848")
                        , T.checkState
                            100
                            (\data ->
                                case lastMessageReactions data of
                                    Ok [ EmojiOrCustomEmoji_CustomEmoji customEmojiId ] ->
                                        case SeqDict.get customEmojiId (E2EHelper.unwrapBackend data.backend).customEmojis of
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
                                                case MessageArray.last channel.messages of
                                                    Just message ->
                                                        case Message.reactionEmojis message |> SeqDict.keys of
                                                            [ EmojiOrCustomEmoji_CustomEmoji _ ] ->
                                                                Ok ()

                                                            [ EmojiOrCustomEmoji_Emoji _ ] ->
                                                                Err "The frontend received the reaction as a unicode emoji (the ❓ fallback) instead of a custom emoji"

                                                            [] ->
                                                                Err "The reaction is missing from the frontend's message"

                                                            _ ->
                                                                Err "Expected exactly one reaction on the frontend's message"

                                                    Nothing ->
                                                        if MessageArray.isEmpty channel.messages then
                                                            Err "The Discord guild channel has no messages on the frontend"

                                                        else
                                                            Err "The frontend's copy of the message is unloaded"

                                            Nothing ->
                                                Err "The Discord guild channel is missing from the frontend"
                                    )
                            )

                        -- A reaction button is a fixed width so that its popup can work
                        -- out which way to open. The width has to grow once the count
                        -- reaches two digits, and past 99 the count doesn't fit at all
                        -- and becomes an infinity sign, so each of those is worth a look.
                        , checkReactingUserCount admin 1
                        , E2EHelper.tallSnapshot admin 100 { name = "Reaction count with one digit" }
                        ]
                            ++ List.map
                                (\index -> T.websocketSendString 10 connection (reactEmojiReactionAdd (reactingUserId index)))
                                (List.range 1 9)
                            ++ [ checkReactingUserCount admin 10
                               , E2EHelper.tallSnapshot admin 100 { name = "Reaction count with two digits" }
                               ]
                            ++ List.map
                                (\index -> T.websocketSendString 10 connection (reactEmojiReactionAdd (reactingUserId index)))
                                (List.range 10 99)
                            ++ [ checkReactingUserCount admin 100
                               , E2EHelper.tallSnapshot admin 100 { name = "Reaction count past 99" }
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
                [ E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
        "Discord gateway resumes with the last sequence number after an unexpected close"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")

                        -- The ready event was sequence number 1, this message moves us up to 204.
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":204,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:00:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1500000000000000204","flags":0,"embeds":[],"edited_timestamp":null,"content":"Message before the connection drops","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Message before the connection drops" ])

                        -- Discord drops the connection with a close code that leaves the session
                        -- intact, so we're allowed to resume rather than start a new session.
                        , T.websocketClose 100 connection (Websocket.UnknownCode 4000) "Unknown error"
                        ]
                    )

                -- A new connection is opened (against the resume_gateway_url from the ready event)
                -- and Discord says hello on it.
                , E2EHelper.andThenWebsocket
                    E2EHelper.gatewayReconnectDelay
                    (\connection _ ->
                        [ T.websocketSendString
                            100
                            connection
                            """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}"""
                        ]
                    )

                -- We resume the old session instead of identifying, and we tell Discord the
                -- sequence number of the last event we actually received.
                , E2EHelper.andThenWebsocket
                    120
                    (\_ websocketState ->
                        [ T.checkState
                            0
                            (\_ ->
                                checkResumeSent
                                    { sessionId = "6d59cfbfb4b2759747dacbd22d86d1dd", seq = 204 }
                                    websocketState
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
                [ E2EHelper.andThenWebsocket 120
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
                    E2EHelper.gatewayReconnectDelay
                    (\connection _ ->
                        [ T.websocketSendString 100 connection """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}""" ]
                    )
                , E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
                            (Route.NoThreadWithFriends Nothing Route.ShowChannelSettings)
                            Nothing
                    , channelsVisible = Route.ChannelsHiddenOnMobile
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
                        , admin.click 100 (Dom.id "guild_emojiSelector_1906")
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
                                                (GuildOrDmId (GuildOrDmId_Guild { guildId = Id.fromInt 0, channelId = Id.fromInt 0 }))
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
                        , Test.Html.Selector.exactText "a@a.aa"
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
                        , E2EHelper.andThenWebsocket 120
                            (\connection _ ->
                                [ T.websocketSendString 100 connection """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}""" ]
                            )
                        , E2EHelper.andThenWebsocket 120
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
        "Discord user posts in a guild forum"
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
                , E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- A forum holds no messages, so a new post is announced by a thread
                          -- create event and nothing else. The post's title is the thread's name.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_CREATE\",\"s\":3,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-08-08T13:54:30.127000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-08-08T13:54:30.127000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1535645724761653309\",\"owner_id\":\"161098476632014848\",\"newly_created\":true,\"name\":\"Test 2\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\"],\"member_count\":1,\"last_message_id\":null,\"id\":\"1535647395881418912\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , -- The post's text follows as a message in the new thread, so until it
                          -- arrives the title is all the forum has.
                          checkDiscordForumAMessages [ "Test 2" ]
                        , checkDiscordForumAThreads []
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":5,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-08T13:54:30.500000+00:00\",\"position\":0,\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"id\":\"1535647395881418912\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"The text of the post\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1535647395881418912\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordForumAMessages [ "Test 2" ]
                        , checkDiscordForumAThreads [ ( 0, [ "The text of the post" ] ) ]
                        , -- A reply to the post is written in the same thread as its text
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":5,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-08T13:55:10.000000+00:00\",\"position\":1,\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"id\":\"1535647395881418913\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"A reply to the post\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1535647395881418912\",\"author\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordForumAMessages [ "Test 2" ]
                        , checkDiscordForumAThreads [ ( 0, [ "The text of the post", "A reply to the post" ] ) ]
                        , -- Discord sends the same event again when someone is added to a
                          -- thread, which shouldn't post the title a second time
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_CREATE\",\"s\":6,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":2,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-08-08T13:54:30.127000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-08-08T13:54:30.127000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1535645724761653309\",\"owner_id\":\"161098476632014848\",\"name\":\"Test 2\",\"message_count\":2,\"member_ids_preview\":[\"161098476632014848\"],\"member_count\":2,\"last_message_id\":\"1535647395881418913\",\"id\":\"1535647395881418912\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , checkDiscordForumAMessages [ "Test 2" ]
                        , checkDiscordForumAThreads [ ( 0, [ "The text of the post", "A reply to the post" ] ) ]
                        , -- A thread in a normal channel hangs off a message in that channel, so
                          -- it has nothing to do with the forum
                          checkDiscordChannelAThreads []
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord user deletes a post in a guild forum"
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
                , user.click 100 (Dom.id "guild_openChannel_1535645724761653309")
                , E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- A message in a normal channel with a thread started from it. The
                          -- thread has the same id as the message, so a thread event that
                          -- confuses the two would rewrite or delete this message.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":3,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-01T12:52:35.803000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"id\":\"1533095101817950311\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"A message with a thread\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordChannelAMessages [ "A message with a thread" ]
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-08-08T13:54:30.127000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-08-08T13:54:30.127000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1535645724761653309\",\"owner_id\":\"161098476632014848\",\"newly_created\":true,\"name\":\"Test 2\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\"],\"member_count\":1,\"last_message_id\":null,\"id\":\"1535647395881418912\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":5,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-08T13:54:30.500000+00:00\",\"position\":0,\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"id\":\"1535647395881418912\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"The text of the post\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1535647395881418912\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordForumAMessages [ "Test 2" ]
                        , checkDiscordForumAThreads [ ( 0, [ "The text of the post" ] ) ]
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Test 2" ])
                        , -- Renaming the post edits the message its title is
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_UPDATE\",\"s\":5,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":1,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-08-08T13:54:30.127000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-08-08T13:54:30.127000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1535645724761653309\",\"owner_id\":\"161098476632014848\",\"name\":\"Test 2 renamed\",\"message_count\":1,\"member_count\":1,\"last_message_id\":\"1535647395881418912\",\"id\":\"1535647395881418912\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , checkDiscordForumAMessages [ "Test 2 renamed" ]
                        , checkDiscordForumAThreads [ ( 0, [ "The text of the post" ] ) ]
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Test 2 renamed" ])
                        , -- Archiving the post leaves its name alone, so nothing changes here
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_UPDATE\",\"s\":6,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":1,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-08-08T13:54:30.127000+00:00\",\"auto_archive_duration\":4320,\"archived\":true,\"archive_timestamp\":\"2026-08-08T14:10:00.000000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1535645724761653309\",\"owner_id\":\"161098476632014848\",\"name\":\"Test 2 renamed\",\"message_count\":1,\"member_count\":1,\"last_message_id\":\"1535647395881418912\",\"id\":\"1535647395881418912\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , checkDiscordForumAMessages [ "Test 2 renamed" ]
                        , -- Renaming a thread in a normal channel isn't a message of ours
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_UPDATE\",\"s\":7,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-08-01T12:54:50.821532+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-08-01T12:54:50.821532+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"name\":\"A renamed normal thread\",\"message_count\":0,\"member_count\":1,\"last_message_id\":null,\"id\":\"1533095101817950311\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , checkDiscordForumAMessages [ "Test 2 renamed" ]
                        , checkDiscordChannelAMessages [ "A message with a thread" ]
                        , -- Deleting the post deletes its title and everything written in it
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_DELETE\",\"s\":8,\"op\":0,\"d\":{\"type\":11,\"parent_id\":\"1535645724761653309\",\"id\":\"1535647395881418912\",\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordForumAMessages [ "<deleted message>" ]
                        , checkDiscordForumAThreads []
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Test 2 renamed" ])
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText LocalState.messageDeleted ])
                        , -- A thread in a normal channel outlives the message it hangs off of, so
                          -- deleting one is none of the forum's business
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_DELETE\",\"s\":9,\"op\":0,\"d\":{\"type\":11,\"parent_id\":\"1072828564317159465\",\"id\":\"1533095101817950311\",\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordForumAMessages [ "<deleted message>" ]
                        , checkDiscordForumAThreads []
                        ]
                    )
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
                , E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- at0232 writes a message in channel A...
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":14,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-01T12:52:35.803000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":\"*_.#\",\"mute\":false,\"joined_at\":\"2016-08-11T03:26:24.940000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533095101817950311\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"other user test\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , -- ...and then starts a thread from it. The message it was started from gets
                          -- the has-thread flag (32) and the thread reuses the message's id.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_UPDATE\",\"s\":15,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-01T12:52:35.803000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":\"*_.#\",\"mute\":false,\"joined_at\":\"2016-08-11T03:26:24.940000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533095101817950311\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"other user test\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_MEMBERS_UPDATE\",\"s\":16,\"op\":0,\"d\":{\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"id\":\"1533095101817950311\",\"added_members\":[{\"user_id\":\"184437096813953035\",\"presence\":{\"user\":{\"username\":\"at28727\",\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"discriminator\":\"0\",\"clan\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"status\":\"online\",\"processed_at_timestamp\":0,\"game\":null,\"client_status\":{\"web\":\"online\"},\"activities\":[]},\"muted\":false,\"mute_config\":null,\"member\":{\"user\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"display_name\":\"AT2\",\"discriminator\":\"0\",\"collectibles\":null,\"bot\":false,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2026-03-15T15:39:29.018000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"join_timestamp\":\"2026-08-01T12:54:51.223301+00:00\",\"id\":\"1533095101817950311\",\"flags\":1}],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_CREATE\",\"s\":17,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-08-01T12:54:50.821532+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-08-01T12:54:50.821532+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"name\":\"other user test\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"member\":{\"user_id\":\"184437096813953035\",\"muted\":false,\"mute_config\":null,\"join_timestamp\":\"2026-08-01T12:54:51.223301+00:00\",\"id\":\"1533095101817950311\",\"flags\":1},\"last_message_id\":\"1533095668212568074\",\"id\":\"1533095101817950311\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , -- Nothing has been written in the thread yet, so the message the thread was
                          -- started from should be the only message in the channel.
                          checkDiscordChannelAMessages [ "other user test" ]
                        , checkDiscordChannelAThreads []
                        , T.andThen
                            100
                            (\data ->
                                case
                                    List.filter
                                        (\request ->
                                            case ( request.url, E2EHelper.decodeCustomRequest request ) of
                                                ( "http://localhost:3000/file/internal/custom-request", Just customRequest ) ->
                                                    (customRequest.url == "https://discord.com/api/v9/channels/1533095101817950311/thread-members/@me")
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
                                            "{\"t\":\"MESSAGE_CREATE\",\"s\":18,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-01T12:54:51.284000+00:00\",\"position\":0,\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":\"*_.#\",\"mute\":false,\"joined_at\":\"2016-08-11T03:26:24.940000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533095670066712636\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"other user writes in other thread\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1533095101817950311\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                                        , checkDiscordChannelAMessages [ "other user test" ]
                                        , checkDiscordChannelAThreads [ ( 0, [ "other user writes in other thread" ] ) ]
                                        , user.checkView
                                            100
                                            (Test.Html.Query.has
                                                [ Test.Html.Selector.exactText "other user test"
                                                , Test.Html.Selector.exactText "other user writes in other thread"
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
        "Unlinked Discord user starts thread from the linked user's message"
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
                , E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- The linked account (at28727) writes a message in channel A...
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":9,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-01T12:52:19.786000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2026-03-15T15:39:29.018000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533095034637910096\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"test\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , -- ...and then at0232 starts a thread from it.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_UPDATE\",\"s\":10,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-01T12:52:19.786000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2026-03-15T15:39:29.018000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533095034637910096\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"test\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_CREATE\",\"s\":11,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-08-01T12:53:03.078891+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-08-01T12:53:03.078891+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"newly_created\":true,\"name\":\"test\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"last_message_id\":null,\"id\":\"1533095034637910096\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_MEMBER_UPDATE\",\"s\":12,\"op\":0,\"d\":{\"user_id\":\"184437096813953035\",\"muted\":false,\"mute_config\":null,\"join_timestamp\":\"2026-08-01T12:53:03.092396+00:00\",\"id\":\"1533095034637910096\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , -- Discord posts a thread starter message (type 21) in the new thread. It has
                          -- no content, it only points back at the message the thread was started from,
                          -- so it shouldn't show up as a message in the thread.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":13,\"op\":0,\"d\":{\"type\":21,\"tts\":false,\"timestamp\":\"2026-08-01T12:53:03.103000+00:00\",\"position\":0,\"pinned\":false,\"message_reference\":{\"type\":0,\"message_id\":\"1533095034637910096\",\"guild_id\":\"705745250815311942\",\"channel_id\":\"1072828564317159465\"},\"mentions\":[{\"username\":\"at28727\",\"public_flags\":0,\"primary_guild\":null,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2026-03-15T15:39:29.018000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"}],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":\"*_.#\",\"mute\":false,\"joined_at\":\"2016-08-11T03:26:24.940000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533095216322576657\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1533095034637910096\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordChannelAMessages [ "test" ]
                        , checkDiscordChannelAThreads []
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "<empty>" ])
                        , -- at0232 writes the first real message in the thread.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":14,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-08-01T12:53:10.284000+00:00\",\"position\":1,\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":\"*_.#\",\"mute\":false,\"joined_at\":\"2016-08-11T03:26:24.940000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533095300000000000\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"First message inside thread\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1533095034637910096\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordChannelAMessages [ "test" ]
                        , checkDiscordChannelAThreads [ ( 0, [ "First message inside thread" ] ) ]
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
                , E2EHelper.andThenWebsocket 120
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
                                        , -- A stand-alone thread has no message to hang off of, so the
                                          -- thread-created message stands in for one.
                                          checkDiscordChannelAMessages [ "Thread title" ]
                                        , checkDiscordChannelAThreads [ ( 0, [ "Thread message" ] ) ]
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
        "Unlinked Discord user starts thread from an old message"
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
                , E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- at0232 writes a message in channel A...
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533000000000000001\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Old message\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , -- ...and much later starts a thread from it.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_UPDATE\",\"s\":5,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-03-26T12:10:08.752000+00:00\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533000000000000001\",\"flags\":32,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Old message\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , -- When the message a thread is started from is old, Discord also posts a
                          -- thread-created message (type 18) in the parent channel to point at the new
                          -- thread. The thread already hangs off the old message here, so the
                          -- thread-created message shouldn't show up as a message of its own.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":6,\"op\":0,\"d\":{\"type\":18,\"tts\":false,\"timestamp\":\"2026-04-02T09:02:31.114000+00:00\",\"pinned\":false,\"message_reference\":{\"type\":0,\"guild_id\":\"705745250815311942\",\"channel_id\":\"1533000000000000001\"},\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533096000000000000\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Thread from old message\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , T.websocketSendString
                            100
                            connection
                            "{\"t\":\"THREAD_CREATE\",\"s\":7,\"op\":0,\"d\":{\"type\":11,\"total_message_sent\":0,\"thread_metadata\":{\"locked\":false,\"create_timestamp\":\"2026-04-02T09:02:31.114000+00:00\",\"auto_archive_duration\":4320,\"archived\":false,\"archive_timestamp\":\"2026-04-02T09:02:31.114000+00:00\"},\"rate_limit_per_user\":0,\"parent_id\":\"1072828564317159465\",\"owner_id\":\"161098476632014848\",\"newly_created\":true,\"name\":\"Thread from old message\",\"message_count\":0,\"member_ids_preview\":[\"161098476632014848\",\"184437096813953035\"],\"member_count\":2,\"last_message_id\":null,\"id\":\"1533000000000000001\",\"guild_id\":\"705745250815311942\",\"flags\":0}}"
                        , checkDiscordChannelAMessages [ "Old message" ]
                        , checkDiscordChannelAThreads []
                        , -- at0232 writes the first message in the thread. It belongs in the thread
                          -- hanging off the old message.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":8,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-02T09:02:35.284000+00:00\",\"position\":0,\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"1533096100000000000\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Message in old message thread\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1533000000000000001\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"primary_guild\":null,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"display_name_styles\":null,\"discriminator\":\"0\",\"collectibles\":null,\"clan\":null,\"avatar_decoration_data\":null,\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordChannelAMessages [ "Old message" ]
                        , checkDiscordChannelAThreads [ ( 0, [ "Message in old message thread" ] ) ]
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Reloading a Discord channel loads its threads"
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
                , -- Admins can reload a Discord channel to load its messages again.
                  reloadDiscordChannelA admin (ChangeId 0)
                , -- The thread created message for the thread started from "Old message" is left out,
                  -- the one for the stand-alone thread is kept since that thread has no other message
                  -- to hang off of.
                  checkDiscordChannelAMessages [ "Old message", "Stand-alone thread", "Hello from history" ]
                , -- Every message that has a thread gets it loaded, whether the thread is archived
                  -- (the one on "Hello from history") or not, and the thread hangs off the message
                  -- it was started from. The thread starter message in the first thread is left out.
                  checkDiscordChannelAThreads
                    [ ( 0, [ "Message in old message thread" ] )
                    , ( 1, [ "Message in stand-alone thread" ] )
                    , ( 2, [ "Message in archived thread" ] )
                    ]
                , -- The thread created message that was left out has a thread as well, but it's the
                  -- same thread as the one on "Old message", so it shouldn't be loaded twice.
                  T.checkState
                    100
                    (\data ->
                        case
                            List.filter
                                (\request ->
                                    case E2EHelper.decodeCustomRequest request of
                                        Just customRequest ->
                                            String.startsWith
                                                "https://discord.com/api/v9/channels/1533000000000000001/messages"
                                                customRequest.url

                                        Nothing ->
                                            False
                                )
                                data.httpRequests
                        of
                            [ _ ] ->
                                Ok ()

                            requests ->
                                Err
                                    ("Expected the messages of the thread on \"Old message\" to be loaded once but they were loaded "
                                        ++ String.fromInt (List.length requests)
                                        ++ " times"
                                    )
                    )
                , E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- A thread still ends up in the right place when someone writes in it after
                          -- the reload.
                          T.websocketSendString
                            100
                            connection
                            "{\"t\":\"MESSAGE_CREATE\",\"s\":4,\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"2026-04-02T09:03:00.000000+00:00\",\"position\":0,\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"id\":\"1533097100000000000\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"Written after the reload\",\"components\":[],\"channel_type\":11,\"channel_id\":\"1533000000000000001\",\"author\":{\"username\":\"at0232\",\"public_flags\":0,\"id\":\"161098476632014848\",\"global_name\":\"AT\",\"discriminator\":\"0\",\"avatar\":\"3d7b1aa7b5149fe06971b6dedf682d82\"},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}"
                        , checkDiscordChannelAMessages [ "Old message", "Stand-alone thread", "Hello from history" ]
                        , checkDiscordChannelAThreads
                            [ ( 0, [ "Message in old message thread", "Written after the reload" ] )
                            , ( 1, [ "Message in stand-alone thread" ] )
                            , ( 2, [ "Message in archived thread" ] )
                            ]
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Reloading a Discord channel keeps the reactions it already had"
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
                , E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ reloadDiscordChannelA admin (ChangeId 0)
                        , checkDiscordChannelAMessages [ "Old message", "Stand-alone thread", "Hello from history" ]
                        , -- Two people react to "Old message", one of them twice, and someone reacts
                          -- to a message written in the thread hanging off it.
                          T.websocketSendString
                            100
                            connection
                            (unicodeReactionAdd
                                { channelId = "1072828564317159465"
                                , messageId = "1533000000000000001"
                                , emoji = "👍"
                                , userId = "161098476632014848"
                                }
                            )
                        , T.websocketSendString
                            100
                            connection
                            (unicodeReactionAdd
                                { channelId = "1072828564317159465"
                                , messageId = "1533000000000000001"
                                , emoji = "👍"
                                , userId = reactingUserId 1
                                }
                            )
                        , T.websocketSendString
                            100
                            connection
                            (unicodeReactionAdd
                                { channelId = "1072828564317159465"
                                , messageId = "1533000000000000001"
                                , emoji = "🎉"
                                , userId = "161098476632014848"
                                }
                            )
                        , T.websocketSendString
                            100
                            connection
                            (unicodeReactionAdd
                                { channelId = "1533000000000000001"
                                , messageId = "1533096100000000000"
                                , emoji = "👀"
                                , userId = "161098476632014848"
                                }
                            )
                        , checkDiscordChannelAMessages
                            [ "Old message 👍×2 🎉×1", "Stand-alone thread", "Hello from history" ]
                        , checkDiscordChannelAThreads
                            [ ( 0, [ "Message in old message thread 👀×1" ] )
                            , ( 1, [ "Message in stand-alone thread" ] )
                            , ( 2, [ "Message in archived thread" ] )
                            ]
                        , -- Reloading builds the messages from what Discord sends back, and Discord
                          -- doesn't include the reactions in a channel's history. The reactions have
                          -- to be carried over from the messages that were already there instead,
                          -- otherwise a reload silently wipes every reaction in the channel.
                          reloadDiscordChannelA admin (ChangeId 1)
                        , checkDiscordChannelAMessages
                            [ "Old message 👍×2 🎉×1", "Stand-alone thread", "Hello from history" ]
                        , checkDiscordChannelAThreads
                            [ ( 0, [ "Message in old message thread 👀×1" ] )
                            , ( 1, [ "Message in stand-alone thread" ] )
                            , ( 2, [ "Message in archived thread" ] )
                            ]
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
                , E2EHelper.andThenWebsocket 120
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
                , E2EHelper.andThenWebsocket 120
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
                , E2EHelper.andThenWebsocket 120
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
                        case SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds of
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
                            case SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds of
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
                            case SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds of
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
                [ E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
        "Swiping a Discord DM closed on mobile stops it counting as viewed"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ admin.resizeWindow 100 E2EHelper.iphone14Window
                        , discordDmMessage connection "Starting a Discord DM"
                        , admin.click 100 (Dom.id "guildIcon_showFriends")
                        , admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")
                        , T.checkState 100 checkBackendIsViewingTheDiscordDm

                        -- Swiping the conversation view away leaves the admin on the
                        -- friends list, which the backend has to hear about, otherwise a
                        -- message arriving now is marked as read on their behalf
                        , admin.click 100 (Dom.id "guild_headerBackButton")
                        , T.checkState 500 checkBackendIsViewingNothing
                        , E2EHelper.tallSnapshot admin 100 { name = "Discord DM swiped closed" }
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
                [ E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
                                            (Test.Html.Query.has [ Test.Html.Selector.text "Start drawing!" ])
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
                                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "Start drawing!" ])
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
                [ E2EHelper.andThenWebsocket 120
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
                [ E2EHelper.andThenWebsocket 120
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
        "Discord messages arriving in the channel you are looking at stay read"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- The admin opens a Discord guild channel, which catches it up
                          admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")

                        -- Someone else writing into the channel while it is on screen leaves
                        -- nothing unread, so no notification icon appears for the guild
                        , discordGuildMessageFromGuildOnlyUser connection "While you watch"
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "While you watch" ])
                        , admin.click 100 (Dom.id "guildIcon_showFriends")
                        , E2EHelper.hasExactText admin [ "You have no unread messages!" ]

                        -- The same message arriving while the admin is elsewhere does count
                        , discordGuildMessageFromGuildOnlyUser connection "While you are away"
                        , E2EHelper.hasNotExactText admin [ "You have no unread messages!" ]
                        , E2EHelper.hasExactText admin [ "While you are away" ]

                        -- And a Discord DM behaves the same way
                        , admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")
                        , discordDmMessage connection "While you watch the DM"
                        , friendLabelHasNoNotificationCircle admin "1472236476401057854" "1"
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord messages written before an account was linked start out read"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- Messages pile up in a Discord guild channel while the admin is the only
                          -- at-chat user with a Discord account linked.
                          discordGuildMessageFromGuildOnlyUser connection "Written before the second user linked"
                        , admin.click 100 (Dom.id "guildIcon_showFriends")
                        , E2EHelper.hasNotExactText admin [ "You have no unread messages!" ]
                        ]
                    )

                -- A second at-chat user links a Discord account that is a member of the same guild.
                , E2EHelper.linkDiscordAndLoginSecondUser
                    E2EHelper.sessionId1
                    "Second User"
                    E2EHelper.userEmail
                    discordOp0Ready
                    discordOp0ReadySupplemental
                    (\_ -> [])

                -- The guild already existed on the backend, so the second user only receives it on a
                -- fresh page load. The messages predate the link, so none of them count as unread.
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    "/"
                    E2EHelper.desktopWindow
                    (\userB ->
                        [ T.andThen
                            10
                            (\data -> [ userB.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , E2EHelper.hasExactText userB [ "You have no unread messages!" ]

                        -- Sanity check: the second user really can see the guild and the message that
                        -- was marked as read, so the check above isn't passing for lack of data.
                        , userB.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , E2EHelper.hasExactText userB [ "Written before the second user linked" ]
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
                [ E2EHelper.andThenWebsocket 120
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
        "Clicking a Discord profile image opens the one-on-one DM with that user"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- A group DM containing the linked account, at0232 and kess is created and
                          -- at0232 writes a message in it.
                          T.websocketSendString 100 connection discordGroupDmChannelCreate
                        , discordGroupDmMessage connection "Hello everyone in the group!"
                        , admin.click 100 (Dom.id "guildsColumn_openDiscordDm_1500000000000000099")
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Hello everyone in the group!" ])

                        -- Clicking at0232's profile image leaves the group DM and opens the
                        -- one-on-one Discord DM channel shared with them instead.
                        , admin.click 100 (Pages.Guild.profileImageButtonId (Id.fromInt 0))
                        , admin.checkModel 100 (checkDiscordDmRoute at0232DiscordDmChannelId)
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Long pressing a Discord guild message offers to DM whoever wrote it"
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
        , -- A phone sized client on the same session, opened straight onto the Bot Test
          -- guild's channel A, so that long pressing a message opens the mobile menu.
          T.connectFrontend
            100
            E2EHelper.sessionId0
            (Route.encode
                (Route.DiscordGuildRoute
                    { currentDiscordUserId = E2EHelper.currentDiscordUserId
                    , guildId = E2EHelper.botTestGuild
                    , channelRoute =
                        Route.DiscordChannel_ChannelRoute
                            E2EHelper.botTestGuild_ChannelA
                            (Route.NoThreadWithFriends Nothing HideChannelSettings)
                            Nothing
                    , channelsVisible = Route.ChannelsHiddenOnMobile
                    }
                )
            )
            E2EHelper.iphone14Window
            (\admin ->
                [ T.andThen
                    10
                    (\data -> [ admin.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.safariIphone) ])
                , E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- `AT` is a Bot Test member that the linked Discord account shares no
                          -- DM channel with, and the frontend can't create one, so long pressing
                          -- their message opens a menu without the DM option.
                          discordGuildMessageFromGuildOnlyUser connection "There is no DM channel with me"
                        , longPressLastDiscordGuildMessage admin
                        , admin.checkView 600 (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_close" ])
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_openDm" ])
                        , admin.click 100 (Dom.id "messageMenu_close")
                        , releaseLongPress admin

                        -- `at0232` does share a one-on-one DM channel with the linked account, so
                        -- their message gets the DM option, which opens that channel.
                        , discordGuildMessage connection "You can DM me"
                        , longPressLastDiscordGuildMessage admin
                        , admin.checkView 600 (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_openDm" ])
                        , E2EHelper.tallSnapshot admin 100 { name = "Discord message menu with DM this user option" }
                        , admin.click 100 (Dom.id "messageMenu_openDm")
                        , admin.checkModel 100 (checkDiscordDmRoute at0232DiscordDmChannelId)
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
                  E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ T.websocketSendString 100 connection E2EHelper.privateDiscordChannelCreateEvent ]
                    )
                , admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Members (3)" ])
                , admin.click 100 (Dom.id "guild_openChannel_1500000000000000777")
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Members (0)" ])
                , -- Sanity check: the backend stored the private channel with its overwrites.
                  T.checkState
                    100
                    (\data ->
                        case SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds of
                            Just guild ->
                                case SeqDict.get E2EHelper.privateDiscordChannelId guild.channels of
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
                , E2EHelper.writeMessage admin 100 "Message in secret channel"
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
                        case SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds of
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
                        , userB.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , userB.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "secret-channel" ])
                        , userB.snapshotView 100 { name = "Shouldn't see private channel" }
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
                                                        if SeqDict.member E2EHelper.privateDiscordChannelId guild.channels then
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
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    (Route.encode
                        (Route.DiscordGuildRoute
                            { currentDiscordUserId = E2EHelper.secondDiscordUserId
                            , guildId = checkGuildVisibleMessageCountGuildId
                            , channelRoute =
                                Route.DiscordChannel_ChannelRoute
                                    E2EHelper.privateDiscordChannelId
                                    (Route.NoThreadWithFriends Nothing HideChannelSettings)
                                    Nothing
                            , channelsVisible = Route.ChannelsHiddenOnMobile
                            }
                        )
                    )
                    E2EHelper.desktopWindow
                    (\userB ->
                        [ T.andThen
                            10
                            (\data -> [ userB.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , userB.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "secret-channel" ])
                        , userB.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Channel does not exist" ])
                        , userB.snapshotView 100 { name = "Shouldn't see private channel even when directly linked" }
                        ]
                    )
                , -- Regression: after the second user's Discord auth expires (NeedsAuthAgain), an
                  -- on-demand ViewDiscordChannel request must still be denied. Before the fix, the
                  -- NeedsAuthAgain branch of asDiscordGuildChannelMember_AllowUserThatNeedsAuthAgain
                  -- skipped the canViewDiscordChannel check the FullData branch performs, letting a
                  -- guild member whose token expired read a private channel they can't view.
                  -- First seed the private channel with a message only the admin should be able to read.
                  T.andThen
                    100
                    (\data ->
                        case E2EHelper.websocketByDiscordToken "legit-token" data of
                            Just ( adminConnection, _ ) ->
                                [ T.websocketSendString 100 adminConnection (E2EHelper.privateDiscordChannelMessageEvent 300 "SUPERSECRETNEEDLE1") ]

                            Nothing ->
                                [ T.checkState 0 (\_ -> Err "Couldn't find the admin's Discord websocket") ]
                    )
                , T.checkState
                    500
                    (\data ->
                        case
                            SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds
                                |> Maybe.andThen (\guild -> SeqDict.get E2EHelper.privateDiscordChannelId guild.channels)
                        of
                            Just channel ->
                                if IdArray.length channel.messages >= 1 then
                                    Ok ()

                                else
                                    Err "The admin's secret message never reached the private channel"

                            Nothing ->
                                Err "The private channel is missing from the backend"
                    )
                , -- The second user's Discord auth expires, moving their linked account into NeedsAuthAgain.
                  T.andThen
                    100
                    (\data ->
                        case E2EHelper.websocketByDiscordToken E2EHelper.secondDiscordToken data of
                            Just ( connection, _ ) ->
                                [ T.websocketClose 100 connection Websocket.NormalClosure "Authentication failed." ]

                            Nothing ->
                                [ T.checkState 0 (\_ -> Err "Couldn't find the second user's Discord websocket") ]
                    )
                , T.checkState
                    100
                    (\data ->
                        case SeqDict.get E2EHelper.secondDiscordUserId (E2EHelper.unwrapBackend data.backend).discordUsers of
                            Just (DiscordUserData.NeedsAuthAgain _) ->
                                Ok ()

                            _ ->
                                Err "The second user's Discord account wasn't put into the NeedsAuthAgain state, so the expired-auth scenario can't be verified"
                    )
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    "/"
                    E2EHelper.desktopWindow
                    (\userC ->
                        [ T.andThen
                            10
                            (\data -> [ userC.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , -- Wait for the frontend to finish loading before enabling logging, since the
                          -- EnableToFrontendLogging handler only runs once the frontend is in the Loaded state.
                          userC.update 200 (Audio.userMsg Types.EnableToFrontendLogging)
                        , -- Directly request to view the private channel as the (now expired) second user.
                          userC.sendToBackend
                            100
                            (LocalModelChangeRequest
                                (ChangeId 900)
                                (Local_CurrentlyViewing
                                    { markMessagesAsViewed = False }
                                    (ViewDiscordChannel
                                        { id =
                                            { guildId = E2EHelper.botTestGuild
                                            , channelId = E2EHelper.privateDiscordChannelId
                                            , currentUserId = E2EHelper.secondDiscordUserId
                                            }
                                        , previouslyLastViewedMessage = UserSession.DontCare
                                        }
                                        UserSession.EmptyPlaceholder
                                    )
                                )
                            )
                        , T.checkState
                            500
                            (\after ->
                                case SeqDict.get userC.clientId after.frontends |> Maybe.map Audio.userModel of
                                    Just (Types.Loaded loaded) ->
                                        case loaded.toFrontendLogs of
                                            Just logs ->
                                                if Array.isEmpty (Array.filter (\toFrontend -> String.contains "SECRETNEEDLE" (Debug.toString toFrontend)) logs) then
                                                    Ok ()

                                                else
                                                    Err "The second user, whose Discord auth expired, read the private channel's messages via ViewDiscordChannel"

                                            Nothing ->
                                                Err "The second user should have been logging ToFrontend"

                                    _ ->
                                        Err "The second user's frontend didn't load"
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord channel made private via CHANNEL_UPDATE stops being visible"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\_ ->
                let
                    -- Whether a plain guild member (the second user's Discord account, which
                    -- has no special roles) is allowed to view the regular channel on the
                    -- backend. This is the exact check the backend uses to decide what to
                    -- serve, so it pinpoints whether the permission overwrites are current.
                    secondUserCanView : Bool -> { a | backend : E2EHelper.BackendModel2 } -> Result String ()
                    secondUserCanView expected data =
                        case SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds of
                            Just guild ->
                                case SeqDict.get E2EHelper.regularDiscordChannelId guild.channels of
                                    Just channel ->
                                        if LocalState.canViewDiscordChannel E2EHelper.botTestGuild channel guild E2EHelper.secondDiscordUserId == expected then
                                            Ok ()

                                        else if expected then
                                            Err "The public channel should be viewable by a plain guild member but isn't"

                                        else
                                            Err "The channel was made private via CHANNEL_UPDATE, but a plain guild member can still view it on the backend (the updated permission overwrites weren't applied)"

                                    Nothing ->
                                        Err "The backend doesn't have the regular channel"

                            Nothing ->
                                Err "The backend doesn't have the Bot Test guild"
                in
                [ -- The admin's linked Discord account creates a channel that @everyone may view.
                  E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ T.websocketSendString 100 connection E2EHelper.regularDiscordChannelCreateEvent ]
                    )
                , -- While public, a plain guild member can view it.
                  T.checkState 100 (secondUserCanView True)
                , -- The admin makes the channel private: @everyone is now denied View Channel.
                  -- (Sent on the admin's gateway before the second user links, so there is only
                  -- one websocket connection for andThenWebsocket to resolve.)
                  E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ T.websocketSendString 100 connection E2EHelper.regularDiscordChannelBecomesPrivateEvent ]
                    )
                , -- Regression check: the backend applied the CHANNEL_UPDATE's overwrites, so the
                  -- same member can no longer view the channel. Before the fix the overwrites were
                  -- dropped and this stayed viewable.
                  T.checkState 100 (secondUserCanView False)
                , -- End-to-end: a second at-chat user links that Discord account and loads fresh in
                  -- a new tab. The now-private channel must be absent from their frontend.
                  E2EHelper.linkDiscordAndLoginSecondUser
                    E2EHelper.sessionId1
                    "Second User"
                    E2EHelper.userEmail
                    discordOp0Ready
                    discordOp0ReadySupplemental
                    (\_ -> [])
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    "/"
                    E2EHelper.desktopWindow
                    (\userB ->
                        [ T.andThen
                            10
                            (\data -> [ userB.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , userB.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , userB.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "regular-channel" ])
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
                                                        if SeqDict.member E2EHelper.regularDiscordChannelId guild.channels then
                                                            Err "The second user, whose Discord account can no longer view the channel, still received the now-private channel in their guild"

                                                        else
                                                            Ok ()

                                                    Nothing ->
                                                        Err "The Bot Test guild wasn't delivered to the second user's frontend, so the scenario can't be verified"

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
                            (Route.NoThreadWithFriends Nothing Route.ShowChannelSettings)
                            Nothing
                    , channelsVisible = Route.ChannelsHiddenOnMobile
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

                -- Leave the channel so that the message AT writes next stays unread.
                , viewer.click 100 (Dom.id "guildIcon_showFriends")
                ]
            )

        -- (3) The unread overview on the home page shows the newest message of the Bot Test
        -- channel, which AT wrote, so AT gets loaded for a client that isn't viewing the
        -- guild at all.
        , E2EHelper.andThenWebsocket 120
            (\connection _ ->
                [ T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":300,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-29T00:00:00.000000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"id":"1500000000000000300","flags":0,"embeds":[],"edited_timestamp":null,"content":"Unread message written by AT","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"AT","public_flags":0,"primary_guild":null,"id":"1401255355928936478","global_name":null,"display_name_styles":null,"discriminator":"0275","collectibles":null,"bot":true,"avatar_decoration_data":null,"avatar":"34f894fcc2d53b98b2d6c99228b814a7"},"attachments":[],"guild_id":"705745250815311942"}}"""
                ]
            )
        , T.connectFrontend
            100
            E2EHelper.sessionId0
            (Route.encode Route.HomePageRoute)
            E2EHelper.desktopWindow
            (\overviewViewer ->
                [ T.andThen
                    10
                    (\data -> [ overviewViewer.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                , overviewViewer.checkModel
                    200
                    (checkDiscordUserLoaded "Discord guild-only member AT" True guildOnlyDiscordUserId)
                , overviewViewer.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.text "Unread message written by AT" ])
                ]
            )
        ]
    , E2EHelper.startTest
        "Unread overview names a Discord user that arrives with a new message"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- The admin is looking at the unread overview and has never opened the Bot
                          -- Test guild, so its members aren't loaded.
                          admin.checkModel
                            100
                            (checkDiscordUserLoaded "Discord guild-only member AT" False guildOnlyDiscordUserId)
                        , discordGuildMessageFromGuildOnlyUser connection "Written by someone we never loaded"
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "Written by someone we never loaded" ])
                        , -- The message brought its writer along, so the overview can name them
                          admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "<missing>" ])
                        , admin.checkModel
                            100
                            (checkDiscordUserLoaded "Discord guild-only member AT" True guildOnlyDiscordUserId)
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Guild emojis update"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- The Bot Test guild starts out with a single custom emoji from the ready payload.
                          T.checkState 100 (checkGuildCustomEmojis admin [ "elm" ])
                        , -- Adding an emoji on Discord: the new emoji gets downloaded and becomes usable.
                          T.websocketSendString 100 connection """{"t":"GUILD_EMOJIS_UPDATE","s":10,"op":0,"d":{"guild_id":"705745250815311942","emojis":[{"roles":[],"require_colons":true,"name":"elm","managed":false,"id":"888159336168300574","available":true,"animated":false},{"roles":[],"require_colons":true,"name":"lamdera","managed":false,"id":"1499999999999999999","available":true,"animated":false}]}}"""
                        , T.checkState 1000 (checkGuildCustomEmojis admin [ "elm", "lamdera" ])
                        , -- Deleting an emoji on Discord: it drops out of the guild even though the
                          -- custom emoji itself is kept around for messages that already use it.
                          T.websocketSendString 100 connection """{"t":"GUILD_EMOJIS_UPDATE","s":11,"op":0,"d":{"guild_id":"705745250815311942","emojis":[{"roles":[],"require_colons":true,"name":"lamdera","managed":false,"id":"1499999999999999999","available":true,"animated":false}]}}"""
                        , T.checkState 1000 (checkGuildCustomEmojis admin [ "lamdera" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord DM messages are held back until the account has used the DM channel"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text "Send at least 4 messages using Discord first" ]
                            )
                        , -- A tampered with frontend can skip the disabled message input, so the backend
                          -- has to check the restriction as well.
                          admin.sendToBackend
                            100
                            (LocalModelChangeRequest
                                (ChangeId 0)
                                (Local_Discord_SendMessage
                                    E2EHelper.startTime
                                    Time.utc
                                    (DiscordGuildOrDmId_Dm
                                        { currentUserId = E2EHelper.currentDiscordUserId
                                        , channelId = discordDmChannelId
                                        }
                                    )
                                    (NonemptyString 'H' "acked")
                                    (NoThreadWithMaybeMessage Nothing)
                                    SeqDict.empty
                                )
                            )
                        , T.checkState
                            100
                            (\data ->
                                if discordDmMessagesPosted data == 0 then
                                    Ok ()

                                else
                                    Err "The backend sent a Discord DM even though the restriction wasn't met"
                            )
                        , -- The account writes 4 messages in the DM channel using Discord itself, which
                          -- is what the restriction is waiting for.
                          discordDmMessageFromLinkedUser connection "One"
                        , discordDmMessageFromLinkedUser connection "Two"
                        , discordDmMessageFromLinkedUser connection "Three"
                        , discordDmMessageFromLinkedUser connection "Four"
                        , T.checkState
                            100
                            (\data ->
                                case
                                    SeqDict.get discordDmChannelId (E2EHelper.unwrapBackend data.backend).discordDmChannels
                                        |> Maybe.andThen
                                            (\channel -> NonemptyDict.get E2EHelper.currentDiscordUserId channel.members)
                                of
                                    Just member ->
                                        if member.messagesSent >= 4 then
                                            Ok ()

                                        else
                                            Err
                                                ("The backend only counted "
                                                    ++ String.fromInt member.messagesSent
                                                    ++ " messages sent with Discord"
                                                )

                                    Nothing ->
                                        Err "The linked account is missing from the Discord DM channel's members"
                            )
                        , -- The message now gets through. It's sent the same way as the earlier attempt
                          -- because the message input only picks up the new count when the channel is
                          -- loaded again.
                          admin.sendToBackend
                            100
                            (LocalModelChangeRequest
                                (ChangeId 1)
                                (Local_Discord_SendMessage
                                    E2EHelper.startTime
                                    Time.utc
                                    (DiscordGuildOrDmId_Dm
                                        { currentUserId = E2EHelper.currentDiscordUserId
                                        , channelId = discordDmChannelId
                                        }
                                    )
                                    (NonemptyString 'H' "ello from at-chat")
                                    (NoThreadWithMaybeMessage Nothing)
                                    SeqDict.empty
                                )
                            )
                        , T.checkState
                            100
                            (\data ->
                                if discordDmMessagesPosted data == 1 then
                                    Ok ()

                                else
                                    Err "The backend didn't send the Discord DM"
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "A message at-chat sends to Discord comes back reading the same way"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , E2EHelper.writeMessage admin 100 "_"
                        , T.andThen
                            400
                            (\data ->
                                case discordMessageContentsPosted data of
                                    content :: _ ->
                                        [ -- The underscore is hidden from Discord's markdown on
                                          -- the way out
                                          T.checkState
                                            0
                                            (\_ ->
                                                if content == "\\_" then
                                                    Ok ()

                                                else
                                                    Err ("Discord was sent " ++ Debug.toString content)
                                            )
                                        , -- Discord hands that same content back, and the
                                          -- backslash has to come off again on the way in. It
                                          -- didn't, which is what this test is here for: the
                                          -- underscore someone typed came home as `\_`.
                                          discordGuildMessage connection (jsonEscaped content)
                                        , admin.checkView
                                            100
                                            (Test.Html.Query.has [ Test.Html.Selector.exactText "_" ])
                                        , admin.checkView
                                            100
                                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "\\_" ])
                                        ]

                                    [] ->
                                        [ T.checkState 0 (\_ -> Err "at-chat sent nothing to Discord") ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "A Discord channel waiting on its messages doesn't claim to be at its start"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ -- A message lands in channel A while the admin is elsewhere, so the
                          -- channel has something to fetch when they open it.
                          discordGuildMessage connection "Written while looking elsewhere"

                        -- The assertions below look at the view midway through a load, so the
                        -- round trip is stretched out to leave room to look.
                        , admin.setNetworkLatency 100 { toBackendLatency = 1000, toFrontendLatency = 1000 }
                        , admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")

                        -- The channel's messages are still on their way, so the header saying
                        -- the channel starts here keeps quiet.
                        , admin.checkView
                            500
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "This is the start of" ])

                        -- Once they land the messages and the header both turn up.
                        , admin.checkView
                            3000
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Written while looking elsewhere" ]
                            )
                        , admin.checkView
                            0
                            (Test.Html.Query.has [ Test.Html.Selector.text "This is the start of" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Handle group DM created"
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
                [ E2EHelper.andThenWebsocket 120
                    (\connection _ ->
                        [ T.websocketSendString 100 connection groupChatCreated
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "at0232, joe" ])
                        , admin.click 100 (Dom.id "guild_discordFriendLabel_1539244611120144464")
                        , admin.snapshotView 100 { name = "Group chat with 3 members " }

                        -- at0232 leaves the group DM. The group DM stops being named after
                        -- them, while joe and the linked account carry on.
                        , T.websocketSendString 100 connection groupChatRecipientRemoved
                        , T.checkBackend
                            100
                            (checkGroupChatMembers
                                [ Discord.idToString E2EHelper.currentDiscordUserId, "12312312312312312312" ]
                            )
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "joe" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "at0232, joe" ])
                        , admin.snapshotView 100 { name = "Group chat with only 2 members left" }
                        , admin.click 100 (Dom.id "guild_discordFriendLabel_1539244611120144464")
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Discord gateway reconnects back off exponentially, and the admin page shows their state"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            (PersonName.toString Backend.adminUser.name)
            E2EHelper.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\_ ->
                [ -- The gateway connection is up and the ready event reset the reconnect backoff.
                  T.connectFrontend
                    100
                    E2EHelper.sessionId0
                    "/admin"
                    E2EHelper.desktopWindow
                    (\adminPage ->
                        [ T.andThen
                            10
                            (\data ->
                                [ adminPage.portEvent
                                    10
                                    "load_startup_data_from_js"
                                    (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                                ]
                            )
                        , adminPage.click
                            100
                            (Pages.Admin.expandSectionButtonId User.DiscordUsersSection)
                        , adminPage.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Websocket open" ])
                        , adminPage.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.exactText "1 failed reconnect" ]
                            )
                        ]
                    )

                -- Discord drops the connection four times in a row without us ever getting back to
                -- ready or resumed, so every reconnect counts as a failed attempt and the wait
                -- before the next one doubles: 0s, 1s, 3s, 7s (each shortened by up to half by the
                -- jitter).
                , gatewayDropAndReconnect 0
                , gatewayDropAndReconnect 1
                , gatewayDropAndReconnect 3
                , gatewayDropAndReconnect 7
                , T.connectFrontend
                    100
                    E2EHelper.sessionId0
                    "/admin"
                    E2EHelper.desktopWindow
                    (\adminPage ->
                        [ T.andThen
                            10
                            (\data ->
                                [ adminPage.portEvent
                                    10
                                    "load_startup_data_from_js"
                                    (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                                ]
                            )
                        , -- The section was expanded above and that's stored on the user, so
                          -- this admin page opens with it already expanded.
                          adminPage.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Websocket open"
                                , Test.Html.Selector.exactText "4 failed reconnects"
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    ]


{-| Have Discord drop the gateway websocket, check that the backend waits out the delay the
backoff picked, and then let it run down so the websocket is back for the next drop.

`unjitteredDelay` is the wait in seconds before the jitter is applied, which is
`2 ^ failedReconnectAttempts - 1`. The jitter only ever shortens it, and never by more than half.

-}
gatewayDropAndReconnect :
    Float
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
gatewayDropAndReconnect unjitteredDelay =
    T.group
        [ E2EHelper.andThenWebsocket
            120
            (\connection _ ->
                [ T.websocketClose 100 connection (Websocket.UnknownCode 4000) "Unknown error"

                -- Check before any time passes, otherwise a delay of 0 has already run down.
                , T.checkBackend 0 (checkGatewayReconnectDelay unjitteredDelay)
                ]
            )

        -- Wait out the longest the delay could have been, plus the tick that reopens the websocket.
        , T.checkBackend (unjitteredDelay * 1000 + E2EHelper.gatewayReconnectDelay) checkGatewayReconnected
        ]


{-| How long the backend still has to wait before it reopens the gateway websocket, in seconds.
-}
pendingGatewayReconnect : E2EHelper.BackendModel2 -> Maybe Float
pendingGatewayReconnect backend =
    SeqDict.get E2EHelper.currentDiscordUserId (E2EHelper.unwrapBackend backend).pendingGatewayReconnects
        |> Maybe.map (\pending -> Duration.inSeconds pending.delay)


checkGatewayReconnectDelay : Float -> E2EHelper.BackendModel2 -> Result String ()
checkGatewayReconnectDelay unjitteredDelay backend =
    case pendingGatewayReconnect backend of
        Just delay ->
            if delay >= unjitteredDelay / 2 && delay <= unjitteredDelay then
                Ok ()

            else
                Err
                    ("Expected the gateway reconnect to be delayed by between "
                        ++ String.fromFloat (unjitteredDelay / 2)
                        ++ "s and "
                        ++ String.fromFloat unjitteredDelay
                        ++ "s, but it was "
                        ++ String.fromFloat delay
                        ++ "s"
                    )

        Nothing ->
            Err "Expected the backend to be waiting to reopen the gateway websocket"


checkGatewayReconnected : E2EHelper.BackendModel2 -> Result String ()
checkGatewayReconnected backend =
    case pendingGatewayReconnect backend of
        Just delay ->
            Err
                ("The gateway websocket hasn't been reopened yet, "
                    ++ String.fromFloat delay
                    ++ "s left to wait"
                )

        Nothing ->
            Ok ()


groupChatCreated : String
groupChatCreated =
    """{"t":"CHANNEL_CREATE"
,"s":3
,"op":0
,"d":
    {"type":3
    ,"recipients":
        [   {"username":"at0232"
            ,"public_flags":0
            ,"primary_guild":null
            ,"id":"161098476632014848"
            ,"global_name":"AT"
            ,"display_name_styles":null
            ,"discriminator":"0"
            ,"collectibles":null
            ,"clan":null
            ,"avatar_decoration_data":null
            ,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"
            }
        ,   {"username":"joe"
            ,"public_flags":0,"primary_guild":null
            ,"id":"12312312312312312312"
            ,"global_name":"joejoe"
            ,"display_name_styles":null
            ,"discriminator":"0"
            ,"collectibles":null
            ,"clan":null
            ,"avatar_decoration_data":null
            ,"avatar":"32132132132132132132132132132132"
            }
        ]
    ,"recipient_flags":0
    ,"owner_id":"161098476632014848"
    ,"origin_channel_id":"185574444641550336"
    ,"name":null
    ,"last_message_id":null
    ,"id":"1539244611120144464"
    ,"icon":null
    ,"flags":0
    ,"blocked_user_warning_dismissed":false
    }
}"""


{-| A `CHANNEL_RECIPIENT_REMOVE` for the group DM `groupChatCreated` makes, saying that
at0232 is no longer in it.
-}
groupChatRecipientRemoved : String
groupChatRecipientRemoved =
    """{"t":"CHANNEL_RECIPIENT_REMOVE","s":6,"op":0,"d":{"user":{"username":"at0232","public_flags":0,"primary_guild":null,"id":"161098476632014848","global_name":"AT","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"3d7b1aa7b5149fe06971b6dedf682d82"},"channel_id":"1539244611120144464"}}"""


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
discordGuildMessage : Websocket.Connection -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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


{-| Send a Discord guild `MESSAGE_CREATE` gateway event for the Bot Test guild's
channel A, sent by `AT` (`guildOnlyDiscordUserId`), a guild member the linked admin
account shares no DM channel with. The message timestamp is the current test time and
the sequence number/message id are derived from it.
-}
discordGuildMessageFromGuildOnlyUser : Websocket.Connection -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
discordGuildMessageFromGuildOnlyUser connection content =
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
                ("{\"t\":\"MESSAGE_CREATE\",\"s\":" ++ unique ++ ",\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"" ++ Iso8601.fromTime data.time ++ "\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"member\":{\"roles\":[],\"premium_since\":null,\"pending\":false,\"nick\":null,\"mute\":false,\"joined_at\":\"2020-05-01T11:39:39.915000+00:00\",\"flags\":0,\"deaf\":false,\"communication_disabled_until\":null,\"banner\":null,\"avatar\":null},\"id\":\"" ++ unique ++ "\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"" ++ content ++ "\",\"components\":[],\"channel_type\":0,\"channel_id\":\"1072828564317159465\",\"author\":{\"username\":\"at\",\"public_flags\":0,\"id\":\"1401255355928936478\",\"global_name\":\"AT\",\"discriminator\":\"0\",\"avatar\":null},\"attachments\":[],\"guild_id\":\"705745250815311942\"}}")
            ]
        )


{-| Send a Discord DM `MESSAGE_CREATE` gateway event (no `guild_id`) for the private
channel the linked admin shares with user `137748026084163584`, sent by that other
user. The message timestamp is the current test time and the sequence number/message
id are derived from it.
-}
checkBackendIsViewingTheDiscordDm : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkBackendIsViewingTheDiscordDm data =
    case E2EHelper.backendViewing E2EHelper.sessionId0 data of
        Ok (UserSession.Viewing_DiscordDm _) ->
            Ok ()

        Ok _ ->
            Err "Expected the backend to have the admin viewing the Discord DM"

        Err error ->
            Err error


checkBackendIsViewingNothing : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkBackendIsViewingNothing data =
    case E2EHelper.backendViewing E2EHelper.sessionId0 data of
        Ok UserSession.Viewing_None ->
            Ok ()

        Ok _ ->
            Err "Expected the backend to hear that the swiped away Discord DM is no longer being viewed"

        Err error ->
            Err error


discordDmMessage : Websocket.Connection -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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


{-| Send a Discord DM `MESSAGE_CREATE` gateway event for the private channel the linked
admin shares with user `137748026084163584`, sent by the linked admin account itself (as
if they wrote it in the Discord app). The message timestamp is the current test time and
the sequence number/message id are derived from it.
-}
discordDmMessageFromLinkedUser : Websocket.Connection -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
discordDmMessageFromLinkedUser connection content =
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
                ("{\"t\":\"MESSAGE_CREATE\",\"s\":" ++ unique ++ ",\"op\":0,\"d\":{\"type\":0,\"tts\":false,\"timestamp\":\"" ++ Iso8601.fromTime data.time ++ "\",\"pinned\":false,\"mentions\":[],\"mention_roles\":[],\"mention_everyone\":false,\"id\":\"" ++ unique ++ "\",\"flags\":0,\"embeds\":[],\"edited_timestamp\":null,\"content\":\"" ++ content ++ "\",\"components\":[],\"channel_type\":1,\"channel_id\":\"1472236476401057854\",\"author\":{\"username\":\"at28727\",\"public_flags\":0,\"id\":\"184437096813953035\",\"global_name\":\"AT2\",\"discriminator\":\"0\",\"avatar\":\"7c40cb63ea11096169c5a4dcb5825a3d\"},\"attachments\":[]}}")
            ]
        )


{-| A string put inside the JSON of a gateway event, where a backslash has to be doubled up
the way Discord's own JSON does it.
-}
jsonEscaped : String -> String
jsonEscaped text =
    String.replace "\\" "\\\\" text


{-| The `content` of every message the backend has posted to Discord, most recent first,
which is the text a Discord client would render.
-}
discordMessageContentsPosted : T.Data FrontendModel E2EHelper.BackendModel2 -> List String
discordMessageContentsPosted data =
    List.filterMap
        (\request ->
            case ( request.url, E2EHelper.decodeCustomRequest request ) of
                ( "http://localhost:3000/file/internal/custom-request", Just customRequest ) ->
                    if customRequest.method == "POST" && String.endsWith "/messages" customRequest.url then
                        Maybe.andThen
                            (\body ->
                                Json.Decode.decodeValue Json.Decode.string body
                                    |> Result.andThen
                                        (Json.Decode.decodeString (Json.Decode.field "content" Json.Decode.string))
                                    |> Result.toMaybe
                            )
                            customRequest.body

                    else
                        Nothing

                _ ->
                    Nothing
        )
        data.httpRequests


{-| The number of messages the backend has posted to the Discord DM channel that
`discordDmMessage` uses.
-}
discordDmMessagesPosted : T.Data FrontendModel E2EHelper.BackendModel2 -> Int
discordDmMessagesPosted data =
    List.Extra.count
        (\request ->
            case ( request.url, E2EHelper.decodeCustomRequest request ) of
                ( "http://localhost:3000/file/internal/custom-request", Just customRequest ) ->
                    (customRequest.url == "https://discord.com/api/v9/channels/1472236476401057854/messages")
                        && (customRequest.method == "POST")

                _ ->
                    False
        )
        data.httpRequests


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
discordGroupDmMessage : Websocket.Connection -> String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> String
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> String
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
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


{-| Check exactly who the backend has as members of the group DM created by
`groupChatCreated`, given their Discord user ids as strings. Both sides are sorted first,
since the order members are stored in doesn't mean anything.
-}
checkGroupChatMembers : List String -> E2EHelper.BackendModel2 -> Result String ()
checkGroupChatMembers expected backend =
    case SeqDict.get groupChatChannelId (E2EHelper.unwrapBackend backend).discordDmChannels of
        Just channel ->
            let
                actual : List String
                actual =
                    NonemptyDict.keys channel.members
                        |> List.Nonempty.toList
                        |> List.map Discord.idToString
                        |> List.sort
            in
            if actual == List.sort expected then
                Ok ()

            else
                Err
                    ("Expected the group DM members to be "
                        ++ String.join ", " (List.sort expected)
                        ++ " but got "
                        ++ String.join ", " actual
                    )

        Nothing ->
            Err "The group DM is missing from the backend"


{-| The Discord group DM that `groupChatCreated` creates.
-}
groupChatChannelId : Discord.Id Discord.PrivateChannelId
groupChatChannelId =
    Unsafe.uint64 "1539244611120144464" |> Discord.idFromUInt64


{-| The one-on-one Discord DM channel the linked account shares with `at0232`. It's listed
in the READY payload's private channels, separately from the group DM that `at0232` is also
a member of.
-}
at0232DiscordDmChannelId : Discord.Id Discord.PrivateChannelId
at0232DiscordDmChannelId =
    Unsafe.uint64 "185574444641550336" |> Discord.idFromUInt64


{-| Renders a Discord message the backend has stored as plain text, so that tests can
compare the contents of a channel or a thread against a list of strings. A message that
has been reacted to gets each of its reactions and how many people added it appended to
its text, for example `Old message 👍×2`.
-}
discordMessageToString : E2EHelper.BackendModel2 -> Message.Message messageId (Discord.Id Discord.UserId) -> String
discordMessageToString backend message =
    let
        text : String
        text =
            case message of
                Message.UserTextMessage data ->
                    RichText.toStringWithGetter Time.utc DiscordUserData.username True (E2EHelper.unwrapBackend backend).discordUsers data.content

                Message.EncryptedUserTextMessage _ ->
                    "<encrypted message>"

                Message.UserJoinedMessage _ _ _ _ ->
                    "<user joined>"

                Message.DeletedMessage _ ->
                    "<deleted message>"

                Message.CallStarted _ ->
                    "<call started>"

                Message.GameStarted _ ->
                    "<game started>"

        reactions : List String
        reactions =
            Message.reactionEmojis message
                |> SeqDict.toList
                |> List.map
                    (\( emoji, users ) ->
                        discordReactionEmojiToString backend emoji ++ "×" ++ String.fromInt (NonemptySet.size users)
                    )
    in
    String.join " " (text :: reactions)


{-| Renders the emoji a reaction was made with. A custom emoji is written the way it's
typed in Discord, so that a reaction with a custom emoji can't be mistaken for one with
the ❓ emoji that stands in for a custom emoji that failed to load.
-}
discordReactionEmojiToString : E2EHelper.BackendModel2 -> EmojiOrCustomEmoji -> String
discordReactionEmojiToString backend emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji unicodeEmoji ->
            Emoji.toString unicodeEmoji

        EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
            case SeqDict.get customEmojiId (E2EHelper.unwrapBackend backend).customEmojis of
                Just customEmoji ->
                    ":" ++ CustomEmoji.emojiNameToString customEmoji.name ++ ":"

                Nothing ->
                    "<missing custom emoji>"


{-| Joins message contents into something readable enough to be shown in a test failure.
-}
messagesToDebugString : List String -> String
messagesToDebugString messages =
    if List.isEmpty messages then
        "no messages"

    else
        List.map (\text -> "\"" ++ text ++ "\"") messages |> String.join ", "


{-| Joins threads and their contents into something readable enough to be shown in a test
failure.
-}
threadsToDebugString : List ( Int, List String ) -> String
threadsToDebugString threads =
    if List.isEmpty threads then
        "no threads"

    else
        List.map
            (\( messageIndex, messages ) ->
                "a thread on message " ++ String.fromInt messageIndex ++ " containing " ++ messagesToDebugString messages
            )
            threads
            |> String.join " and "


{-| Check that the Bot Test guild's channel A contains exactly these messages (in order).
-}
checkDiscordChannelAMessages : List String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkDiscordChannelAMessages expected =
    checkDiscordChannelMessages "channel A" E2EHelper.botTestGuild_ChannelA expected


{-| Check the messages in the Bot Test guild's forum A. A forum's messages are the titles
of the posts in it.
-}
checkDiscordForumAMessages : List String -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkDiscordForumAMessages expected =
    checkDiscordChannelMessages "forum A" E2EHelper.botTestGuild_ForumA expected


checkDiscordChannelMessages :
    String
    -> Discord.Id Discord.ChannelId
    -> List String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkDiscordChannelMessages channelName channelId expected =
    T.checkState
        100
        (\data ->
            case
                SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds
                    |> Maybe.andThen (\guild -> SeqDict.get channelId guild.channels)
            of
                Just channel ->
                    let
                        actual : List String
                        actual =
                            IdArray.toList channel.messages |> List.map (discordMessageToString data.backend)
                    in
                    if actual == expected then
                        Ok ()

                    else
                        Err
                            ("Expected "
                                ++ channelName
                                ++ " to contain "
                                ++ messagesToDebugString expected
                                ++ " but it contains "
                                ++ messagesToDebugString actual
                            )

                Nothing ->
                    Err ("The Bot Test guild's " ++ channelName ++ " is missing from the backend")
        )


{-| Check the threads in the Bot Test guild's channel A against the index of the message
each of them hangs off of and the messages written in them.
-}
checkDiscordChannelAThreads : List ( Int, List String ) -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkDiscordChannelAThreads expected =
    checkDiscordChannelThreads "channel A" E2EHelper.botTestGuild_ChannelA expected


{-| Check the posts in the Bot Test guild's forum A against the index of the title each of
them hangs off of and the messages written in them. A post's text is the first of those
messages and the replies to it are the rest.
-}
checkDiscordForumAThreads : List ( Int, List String ) -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkDiscordForumAThreads expected =
    checkDiscordChannelThreads "forum A" E2EHelper.botTestGuild_ForumA expected


checkDiscordChannelThreads :
    String
    -> Discord.Id Discord.ChannelId
    -> List ( Int, List String )
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkDiscordChannelThreads channelName channelId expected =
    T.checkState
        100
        (\data ->
            case
                SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend data.backend).discordGuilds
                    |> Maybe.andThen (\guild -> SeqDict.get channelId guild.channels)
            of
                Just channel ->
                    let
                        actual : List ( Int, List String )
                        actual =
                            List.map
                                (\( threadId, thread ) ->
                                    ( Id.toInt threadId
                                    , IdArray.toList thread.messages |> List.map (discordMessageToString data.backend)
                                    )
                                )
                                (SeqDict.toList channel.threads)
                                |> List.sortBy Tuple.first
                    in
                    if actual == List.sortBy Tuple.first expected then
                        Ok ()

                    else
                        Err
                            ("Expected "
                                ++ channelName
                                ++ " to have "
                                ++ threadsToDebugString expected
                                ++ " but it has "
                                ++ threadsToDebugString actual
                            )

                Nothing ->
                    Err ("The Bot Test guild's " ++ channelName ++ " is missing from the backend")
        )


{-| The index of the most recent message in the Bot Test guild's channel A.
-}
lastDiscordGuildMessageId : E2EHelper.BackendModel2 -> Maybe (Id.Id Id.ChannelMessageId)
lastDiscordGuildMessageId backend =
    case
        SeqDict.get E2EHelper.botTestGuild (E2EHelper.unwrapBackend backend).discordGuilds
            |> Maybe.andThen (\guild -> SeqDict.get E2EHelper.botTestGuild_ChannelA guild.channels)
    of
        Just channel ->
            if IdArray.isEmpty channel.messages then
                Nothing

            else
                Id.fromInt (IdArray.length channel.messages - 1) |> Just

        Nothing ->
            Nothing


{-| Touch and hold the most recent message in the Bot Test guild's channel A. The message
menu opens half a second later, once the long press timer fires.
-}
longPressLastDiscordGuildMessage :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
longPressLastDiscordGuildMessage actions =
    T.andThen
        100
        (\data ->
            case lastDiscordGuildMessageId data.backend of
                Just messageId ->
                    [ actions.custom
                        100
                        (Pages.Guild.channelMessageHtmlId messageId)
                        "touchstart"
                        (Json.Encode.object
                            [ ( "timeStamp", Json.Encode.float 1000 )
                            , ( "touches"
                              , Json.Encode.object
                                    [ ( "length", Json.Encode.int 1 )
                                    , ( "0"
                                      , Json.Encode.object
                                            [ ( "identifier", Json.Encode.int 0 )
                                            , ( "clientX", Json.Encode.float 50 )
                                            , ( "clientY", Json.Encode.float 150 )
                                            , ( "target"
                                              , Json.Encode.object
                                                    [ ( "id"
                                                      , Pages.Guild.channelMessageHtmlId messageId
                                                            |> Dom.idToString
                                                            |> Json.Encode.string
                                                      )
                                                    ]
                                              )
                                            ]
                                      )
                                    ]
                              )
                            , ( "target", Json.Encode.object [ ( "dataset", Json.Encode.object [] ) ] )
                            ]
                        )
                    ]

                Nothing ->
                    [ actions.checkModel
                        100
                        (\_ -> Err "Expected the Discord guild channel to contain a message")
                    ]
        )


{-| Release the long press so the next one is registered instead of being treated as a
continuation of the previous drag.
-}
releaseLongPress :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
releaseLongPress actions =
    actions.custom
        100
        (Dom.id "elm-ui-root-id")
        "touchend"
        (Json.Encode.object [ ( "timeStamp", Json.Encode.float 2000 ) ])


{-| Check that the frontend is viewing the given Discord DM channel.
-}
checkDiscordDmRoute : Discord.Id Discord.PrivateChannelId -> FrontendModel -> Result String ()
checkDiscordDmRoute channelId model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case loaded.route of
                Route.DiscordDmRoute discordDmRoute ->
                    if discordDmRoute.channelId == channelId then
                        Ok ()

                    else
                        Err "Opened the wrong Discord DM channel"

                _ ->
                    Err "Expected to be viewing a Discord DM channel"

        Types.Loading _ ->
            Err "Expected the frontend to have finished loading"


{-| The Discord DM channel `discordDmMessage` sends messages to.
-}
discordDmChannelId : Discord.Id Discord.PrivateChannelId
discordDmChannelId =
    Unsafe.uint64 "1472236476401057854" |> Discord.idFromUInt64


{-| The most recent message in the Discord DM channel used by `discordDmMessage`.
-}
lastDiscordDmMessage : E2EHelper.BackendModel2 -> Maybe ( Id.Id Id.ChannelMessageId, Message.Message Id.ChannelMessageId (Discord.Id Discord.UserId) )
lastDiscordDmMessage backend =
    case SeqDict.get discordDmChannelId (E2EHelper.unwrapBackend backend).discordDmChannels of
        Just channel ->
            case IdArray.last channel.messages of
                Just message ->
                    Just ( Id.fromInt (IdArray.length channel.messages - 1), message )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing
