module DiscordRecordedTests exposing (discordTests)

import Array
import Backend
import Codec
import CustomEmoji exposing (CustomEmojiData)
import Duration
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Expect
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), GuildOrDmId(..), ThreadRoute(..))
import Json.Encode
import MessageInput
import Pages.Guild
import PersonName
import RecordedTestExtra
import Route
import SeqDict
import Sticker
import Test.Html.Query
import Test.Html.Selector
import Time
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import User


discordTests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
discordTests normalConfig discordOp0Ready discordOp0ReadySupplemental =
    [ RecordedTestExtra.startTest
        "Got rich text embed"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ RecordedTestExtra.andThenWebsocket
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
    , RecordedTestExtra.startTest
        "Message with new custom emoji"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ RecordedTestExtra.andThenWebsocket
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
    , RecordedTestExtra.startTest
        "Got spoilered image"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ RecordedTestExtra.andThenWebsocket
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
    , RecordedTestExtra.startTest
        "Message created by unlinked user containing only embed"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ RecordedTestExtra.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":476,"op":0,"d":{"webhook_id":"1374332266083254363","type":0,"tts":false,"timestamp":"2026-03-31T20:15:05.862000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"id":"1488632753368072280","flags":0,"embeds":[{"url":"https://github.com/lamdera/compiler/pull/92","type":"rich","title":"[lamdera/compiler] Pull request opened: #92   Allow configuring <html lang> via html-lang file","id":"1488632753368072281","description":"Read an optional html-lang file from the project root to set the lang attribute on the generated  tag.  If the file contains e.g. \\"fr\\", the output becomes .  If absent or empty, the tag is plain  as before.  Fixes #84.","content_scan_version":4,"color":38912,"author":{"url":"https://github.com/MavenRain","proxy_icon_url":"https://images-ext-1.discordapp.net/external/z5iI09eMZ6hW8pY8xflOmWevOiHuXRD-pljR_thC38Q/%3Fv%3D4/https/avatars.githubusercontent.com/u/7246681","name":"MavenRain","icon_url":"https://avatars.githubusercontent.com/u/7246681?v=4"}}],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"GitHub","id":"1374332266083254363","global_name":null,"discriminator":"0000","bot":true,"avatar":"e57fd67dc7ca0cc840a0e87a82281bc5"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Title for https://github.com/lamdera/compiler/pull/92" ])
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Discord friend label shows typing indicator"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ RecordedTestExtra.andThenWebsocket
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
    , RecordedTestExtra.startTest
        "Message created by linked user containing url"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ RecordedTestExtra.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , RecordedTestExtra.writeMessage admin 100 "https://www.youtube.com/watch?v=zAFDQH19pV4"
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":3,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-01T10:04:25.211000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1488841459204489398","flags":0,"embeds":[],"edited_timestamp":null,"content":"https://www.youtube.com/watch?v=zAFDQH19pV4","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , T.websocketSendString 1000 connection """{"t":"MESSAGE_UPDATE","s":4,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-01T10:04:25.211000+00:00","pinned":false,"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":[],"premium_since":null,"pending":false,"nick":null,"mute":false,"joined_at":"2025-10-11T19:44:51.312000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1488841459204489398","flags":0,"embeds":[{"video":{"width":720,"url":"https://www.youtube.com/embed/zAFDQH19pV4","placeholder_version":1,"placeholder":"lDgKDIQHiJZyiniCe3ingHsKqA==","height":720,"flags":0},"url":"https://www.youtube.com/watch?v=zAFDQH19pV4","type":"video","title":"Spiral (jackLNDN Remix)","thumbnail":{"width":1280,"url":"https://i.ytimg.com/vi/zAFDQH19pV4/maxresdefault.jpg","proxy_url":"https://images-ext-1.discordapp.net/external/o1Bl70OhMLyAuYI0AvggMLdse0h4epFkr-Nd4Ru9L3I/https/i.ytimg.com/vi/zAFDQH19pV4/maxresdefault.jpg","placeholder_version":1,"placeholder":"lDgKDIQHiJZyiniCe3ingHsKqA==","height":720,"flags":0,"content_type":"image/jpeg"},"provider":{"url":"https://www.youtube.com","name":"YouTube"},"id":"1488841460739739829","description":"Provided to YouTube by Label Worx Limited\\n\\nSpiral (jackLNDN Remix) · Lena Leon · jackLNDN · jackLNDN\\n\\nSpiral (Deluxe Edition)\\n\\n℗ Big Proof Publishing, Danny Danger Publishing, Ultra Empire Music (BMI) obo itself and LRL Music, Whizz Kid II Publishing GmbH, Hooks & Crooks BMG Rights Management GmbH\\n\\nReleased on: 2023-02-10\\n\\nProducer: jackLND...","color":16711680,"author":{"url":"https://www.youtube.com/channel/UCQ8EctjrppQcwBA3lEIlk4w","name":"Lena Leon - Topic"}}],"edited_timestamp":null,"content":"https://www.youtube.com/watch?v=zAFDQH19pV4","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"at28727","public_flags":0,"primary_guild":null,"id":"184437096813953035","global_name":"AT2","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7c40cb63ea11096169c5a4dcb5825a3d"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Title for https://www.youtube.com/watch?v=zAFDQH19pV4" ])
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Link Discord account with login"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\_ -> [])
        ]
    , RecordedTestExtra.startTest "Forwarded message"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ RecordedTestExtra.andThenWebsocket
                    (\connection _ ->
                        [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                        , T.websocketSendString 100 connection """{"t":"MESSAGE_CREATE","s":3293,"op":0,"d":{"type":0,"tts":false,"timestamp":"2026-04-17T16:14:03.131000+00:00","pinned":false,"nonce":"1494732679017398272","message_snapshots":[{"message":{"type":0,"timestamp":"2026-04-17T11:22:04.856000+00:00","mentions":[],"flags":0,"embeds":[],"edited_timestamp":null,"content":"","components":[],"attachments":[{"width":2160,"url":"https://cdn.discordapp.com/attachments/123/321/IMG_1234.jpg?ex=123&is=321&hm=123&","size":517431,"proxy_url":"https://media.discordapp.net/attachments/123/321/1234.jpg?ex=123&is=321&hm=123&","placeholder_version":1,"placeholder":"WlkKDgSql6d2d3d4d4B4gZqYrHCJCGc=","id":"1494732685631946782","height":2461,"filename":"IMG_7203.jpg","content_type":"image/jpeg","content_scan_version":4}]}}],"message_reference":{"type":1,"message_id":"1494659209021751327","channel_id":"1472236476401057854"},"mentions":[],"mention_roles":[],"mention_everyone":false,"member":{"roles":["476506921260810240","734405273103499264","743849378363605082","840010386958581770","776291214478802964","840041852852895765","1030137708531687514"],"premium_since":null,"pending":false,"nick":"cute technology","mute":false,"joined_at":"2018-08-07T17:00:17.616000+00:00","flags":0,"deaf":false,"communication_disabled_until":null,"banner":null,"avatar":null},"id":"1494732685992530114","flags":16384,"embeds":[],"edited_timestamp":null,"content":"","components":[],"channel_type":0,"channel_id":"1072828564317159465","author":{"username":"capysuit","public_flags":0,"primary_guild":null,"id":"339560235050205185","global_name":"gio","display_name_styles":null,"discriminator":"0","collectibles":null,"clan":null,"avatar_decoration_data":null,"avatar":"7d2709668c67727f98ba40ff62611e78"},"attachments":[],"guild_id":"705745250815311942"}}"""
                        , admin.checkView 1000 (Test.Html.Query.hasNot [ Test.Html.Selector.text "empty" ])
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Message with sticker"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ RecordedTestExtra.andThenWebsocket
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
            RecordedTestExtra.sessionId0
            (Route.encode
                (Route.DiscordGuildRoute
                    { currentDiscordUserId = RecordedTestExtra.currentDiscordUserId
                    , guildId = RecordedTestExtra.botTestGuild
                    , channelRoute =
                        Route.DiscordChannel_ChannelRoute
                            RecordedTestExtra.botTestGuild_ChannelA
                            (Route.NoThreadWithFriends Nothing Route.ShowMembersTab)
                    }
                )
            )
            RecordedTestExtra.desktopWindow
            (\admin ->
                [ admin.portEvent 10 "user_agent_from_js" (Json.Encode.string RecordedTestExtra.firefoxDesktop)
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
                , RecordedTestExtra.inviteUser
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
    , RecordedTestExtra.startTest
        "Link Discord account with login to non-existent at-chat account"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            "Steve"
            RecordedTestExtra.userEmail
            True
            discordOp0Ready
            discordOp0ReadySupplemental
            (\user ->
                [ user.click 100 (Dom.id "guild_showUserOptions")
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
    , RecordedTestExtra.startTest
        "Link Discord account already logged in"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId0
            "/"
            RecordedTestExtra.desktopWindow
            (\adminA ->
                [ RecordedTestExtra.handleLogin RecordedTestExtra.firefoxDesktop RecordedTestExtra.adminEmail adminA
                , adminA.click 100 (Dom.id "guild_showUserOptions")
                , adminA.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Loading user data" ])
                , T.connectFrontend
                    100
                    RecordedTestExtra.sessionId0
                    ("/link-discord/?data=" ++ Codec.encodeToString 0 User.linkDiscordDataCodec RecordedTestExtra.discordUserAuth)
                    RecordedTestExtra.desktopWindow
                    (\adminB ->
                        [ adminB.portEvent 10 "user_agent_from_js" (Json.Encode.string RecordedTestExtra.firefoxDesktop)
                        , adminA.checkView
                            200
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Loading user data" ])
                        , RecordedTestExtra.andThenWebsocket
                            (\connection _ ->
                                [ T.websocketSendString 100 connection """{"t":null,"s":null,"op":10,"d":{"heartbeat_interval":41250,"_trace":["[\\"gateway-prd-arm-us-east1-d-swb5\\",{\\"micros\\":0.0}]"]}}""" ]
                            )
                        , RecordedTestExtra.andThenWebsocket
                            (\connection websocketState ->
                                case Array.toList websocketState.dataSent |> List.filter RecordedTestExtra.isOp2 of
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
    , RecordedTestExtra.startTest
        "Ping discord user"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
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
    , RecordedTestExtra.startTest
        "Unlinked Discord user starts thread from message"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\user ->
                [ user.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , RecordedTestExtra.andThenWebsocket
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
                                            case ( request.url, RecordedTestExtra.decodeCustomRequest request ) of
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
    , RecordedTestExtra.startTest
        "Unlinked Discord user starts stand-alone thread"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\user ->
                [ user.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , RecordedTestExtra.andThenWebsocket
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
                                            case ( request.url, RecordedTestExtra.decodeCustomRequest request ) of
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
    , RecordedTestExtra.startTest
        "Discord guild typing indicator"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , RecordedTestExtra.andThenWebsocket
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
                                ++ String.fromInt (Time.posixToMillis (Duration.addTo RecordedTestExtra.startTime (Duration.seconds 3)))
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
    , RecordedTestExtra.startTest
        "Handle new sticker in guild message"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_openDiscordGuild_705745250815311942")
                , RecordedTestExtra.andThenWebsocket
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
    , RecordedTestExtra.startTest
        "Handle new sticker in DM message"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            (PersonName.toString Backend.adminUser.name)
            RecordedTestExtra.adminEmail
            False
            discordOp0Ready
            discordOp0ReadySupplemental
            (\admin ->
                [ admin.click 100 (Dom.id "guild_discordFriendLabel_1472236476401057854")
                , RecordedTestExtra.andThenWebsocket
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
