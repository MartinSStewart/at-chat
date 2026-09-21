module Pages.Home exposing
    ( header
    , loginButtonId
    , loginSignupText
    , view
    )

import Array exposing (Array)
import ChannelDescription
import ChannelName exposing (ChannelName)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord
import DiscordUserData
import DmChannel
import Drawing
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Time as Time
import Emoji
import FileName
import FileStatus exposing (IsEncrypted(..))
import FrontendExtra
import Game
import GuildName exposing (GuildName)
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, UserId)
import IdArray
import LinkedAndOtherDiscordUsers exposing (LinkedAndOtherDiscordUsers(..))
import List.Nonempty exposing (Nonempty(..))
import Local
import LocalState exposing (DiscordFrontendGuild, FrontendChannel, FrontendGuild)
import MembersAndOwner
import Message exposing (GameType(..), Message(..), RepliedTo(..))
import MessageArray exposing (MessageArray)
import MyUi
import NonemptyDict
import NonemptySet
import Pages.Guild
import RichText
import Route exposing (ChannelSidebarMode(..), ChannelsVisibleOnMobile(..), Route(..))
import SeqDict
import SeqSet
import SessionIdHash
import Set
import String.Nonempty exposing (NonemptyString(..))
import TextEditor
import Thread
import Types exposing (AdminStatusLoginData(..), FrontendMsg_(..), LoadedFrontend, LoginData, LoginStatus(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Input
import Ui.Shadow
import Unsafe
import User exposing (BackendUser, FrontendUser)
import UserAgent exposing (UserAgent)
import UserColor
import UserSession exposing (ChannelHeaderTab(..), ToBeFilledInByBackend(..), Viewing(..))
import VisibleMessages
import WordSpellingGame exposing (Action(..), ActionWithTime, IsValid(..), Letter(..), LetterOrWildcard(..), ReactionTarget(..))


loginSignupText : String
loginSignupText =
    "Login/Signup"


header : Bool -> Route -> LoginStatus -> Element FrontendMsg_
header isMobile route loginStatus =
    Ui.el
        [ Ui.background MyUi.background1
        , Ui.Shadow.shadows [ { x = 0, y = 1, blur = 2, size = 0, color = Ui.rgba 0 0 0 0.05 } ]
        ]
        (Ui.row
            [ MyUi.htmlStyle "padding" ("calc(4px + " ++ MyUi.insetTop ++ ")" ++ " 16px 0 16px")
            , Ui.contentCenterY
            , MyUi.notoSans
            , Ui.widthMax 1280
            , Ui.centerX
            ]
            [ Ui.image
                [ Ui.width (Ui.px 64)
                , Ui.paddingWith { top = 4, left = 8, right = 8, bottom = 8 }
                , Ui.Input.button (PressedLink (HomePageRoute Nothing))
                ]
                { source = "/cacheable/at-logo-no-background.png"
                , description = "Logo"
                , onLoad = Nothing
                }
            , case loginStatus of
                LoggedIn _ ->
                    Ui.none

                NotLoggedIn notLoggedIn ->
                    MyUi.elButton
                        loginButtonId
                        PressedShowLogin
                        (buttonAttributes isMobile (notLoggedIn.loginForm /= Nothing || Route.requiresLogin route))
                        (Ui.text loginSignupText)
            ]
        )


buttonAttributes : Bool -> Bool -> List (Ui.Attribute msg)
buttonAttributes isMobile isSelected =
    [ Ui.Font.weight 600
    , Ui.rounded 8
    , Ui.padding 8
    , Ui.alignRight
    , Ui.width Ui.shrink
    , Ui.height Ui.fill
    , Ui.paddingWith { left = 16, right = 16, top = 4, bottom = 8 }
    , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }
    , Ui.attrIf isSelected (Ui.background MyUi.background3)
    , Ui.attrIf isSelected (MyUi.outwardBottomCorner 16 True MyUi.background3)
    , Ui.attrIf isSelected (MyUi.outwardBottomCorner 16 False MyUi.background3)
    , Ui.contentCenterY
    , Ui.Font.color
        (if isSelected then
            MyUi.font1

         else
            MyUi.font3
        )
    , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
    ]


loginButtonId : HtmlId
loginButtonId =
    Dom.id "homePage_loginButton"


previewUserId : Id UserId
previewUserId =
    Id.fromInt 0


previewGuildId : Id GuildId
previewGuildId =
    Id.fromInt 0


previewGameGuildId : Id GuildId
previewGameGuildId =
    Id.fromInt 1


previewChannelId : Id ChannelId
previewChannelId =
    Id.fromInt 0


previewGuildName : GuildName
previewGuildName =
    Unsafe.guildName "Friends & chat"


previewGameGuildName : GuildName
previewGameGuildName =
    Unsafe.guildName "video game gang"


previewChannelName : ChannelName
previewChannelName =
    Unsafe.channelName "general"


petPicsChannelName : ChannelName
petPicsChannelName =
    Unsafe.channelName "pet-pics"


previewUser : BackendUser
previewUser =
    let
        user =
            User.init (Time.millisToPosix 0) (Unsafe.personName "Sven Svensson") (Unsafe.emailAddress "you@at-chat.app") False
    in
    { user
        | lastViewedMessage =
            SeqDict.fromList
                [ ( GuildOrDmId
                        (GuildOrDmId_Guild
                            { guildId = previewGuildId
                            , channelId = previewChannelId
                            }
                        )
                  , Id.fromInt 5
                  )
                ]
    }


previewOtherUsers : SeqDict.SeqDict (Id UserId) FrontendUser
previewOtherUsers =
    SeqDict.fromList
        [ ( Id.fromInt 1
          , { name = Unsafe.personName "jobaly Joe"
            , color = UserColor.default
            , icon = Nothing
            , publicKey = Nothing
            }
          )
        , ( Id.fromInt 2
          , { name = Unsafe.personName "boog'les_the_spy.jpig"
            , color = UserColor.fromParts { hue = 0, lightness = 12, saturation = 11 }
            , icon = Just (FileStatus.fileHash "defrqz-9TjEnuXDZnPc8zD1VoeugOLHh_7-sWw")
            , publicKey = Nothing
            }
          )
        , ( Id.fromInt 3
          , { name = Unsafe.personName "antichokehards"
            , color = UserColor.fromParts { hue = 4, lightness = 10, saturation = 15 }
            , icon = Just (FileStatus.fileHash "7kTsE8OAyWGK_3AsOpZje0ySNF-kqCH_RnemPg")
            , publicKey = Nothing
            }
          )
        ]


previewDiscordUserId : Discord.Id Discord.UserId
previewDiscordUserId =
    Unsafe.uint64 "185574444641550336" |> Discord.idFromUInt64


previewOtherDiscordUserId : Discord.Id Discord.UserId
previewOtherDiscordUserId =
    Unsafe.uint64 "705745250815311942" |> Discord.idFromUInt64


previewDiscordDmChannelId : Discord.Id Discord.PrivateChannelId
previewDiscordDmChannelId =
    Unsafe.uint64 "1072828564317159465" |> Discord.idFromUInt64


previewDiscordGuildId : Discord.Id Discord.GuildId
previewDiscordGuildId =
    Unsafe.uint64 "161098476632014848" |> Discord.idFromUInt64


previewDiscordGuildName : GuildName
previewDiscordGuildName =
    Unsafe.guildName "speedrun club"


previewDiscordUsers : LinkedAndOtherDiscordUsers
previewDiscordUsers =
    LinkedAndOtherDiscordUsers
        (SeqDict.singleton
            previewOtherDiscordUserId
            { name = Unsafe.personName "hexadecimoose"
            , icon = Nothing
            , color = UserColor.fromParts { hue = 10, lightness = 11, saturation = 13 }
            }
        )
        (SeqDict.singleton
            previewDiscordUserId
            { name = Unsafe.personName "Sven Svensson"
            , color = UserColor.default
            , icon = Nothing
            , email = Nothing
            , needsAuthAgain = False
            , linkedAt = Time.millisToPosix 0
            , isLoadingData = DiscordUserData.DiscordUserLoadedSuccessfully
            }
        )


{-| How long ago something in the preview happened. The offsets are counted back from the
current time on every render, so the conversations always read the same however long the page
has been open, and anything a day or more back falls on an earlier date and gets a divider.
-}
previewMinutesAgo : Time.Posix -> Float -> Time.Posix
previewMinutesAgo time minutes =
    Duration.addTo time (Duration.minutes -minutes)


previewMessage : Time.Posix -> userId -> NonemptyString -> Message messageId userId
previewMessage createdAt createdBy text =
    UserTextMessage
        { createdAt = createdAt
        , createdBy = createdBy
        , content =
            { content = RichText.fromNonemptyString Time.utc SeqDict.empty text
            , embeds = Array.empty
            , attachedFiles = SeqDict.empty
            }
        , reactions = SeqDict.empty
        , editedAt = Nothing
        , repliedTo = NoReply
        , drawings = Nothing
        }


previewThread : List (Message ThreadMessageId (Id UserId)) -> Thread.FrontendThread
previewThread messages =
    let
        messages2 : MessageArray ThreadMessageId (Id UserId)
        messages2 =
            List.foldl MessageArray.push MessageArray.empty messages
    in
    { messages = messages2
    , visibleMessages = VisibleMessages.init True (MessageArray.length messages2)
    , lastTypedAt = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


previewDmChannel :
    List (Message ChannelMessageId (Id UserId))
    -> SeqDict.SeqDict (Id ChannelMessageId) Thread.FrontendThread
    -> DmChannel.FrontendDmChannel
previewDmChannel messages threads =
    let
        messages2 : MessageArray ChannelMessageId (Id UserId)
        messages2 =
            List.foldl MessageArray.push MessageArray.empty messages

        dmChannel : DmChannel.FrontendDmChannel
        dmChannel =
            DmChannel.frontendInit
    in
    { dmChannel
        | messages = messages2
        , visibleMessages = VisibleMessages.init True (MessageArray.length messages2)
        , threads = threads
    }


previewDmChannels : Time.Posix -> SeqDict.SeqDict (Id UserId) DmChannel.FrontendDmChannel
previewDmChannels time =
    SeqDict.fromList
        [ ( Id.fromInt 1
          , previewDmChannel
                [ previewMessage (previewMinutesAgo time 1612) (Id.fromInt 1) (NonemptyString 'd' "id you ever find out what bird that was")
                , previewMessage (previewMinutesAgo time 1607) previewUserId (NonemptyString 'a' " sandpiper, she says")
                , previewMessage (previewMinutesAgo time 1601) (Id.fromInt 1) (NonemptyString 'h' "uh. it looked bigger than that")
                , previewMessage (previewMinutesAgo time 37) (Id.fromInt 1) (NonemptyString 'a' "nyway, are you around on saturday?")
                ]
                (SeqDict.singleton
                    (Id.fromInt 0)
                    (previewThread
                        [ previewMessage (previewMinutesAgo time 1598) previewUserId (NonemptyString 'l' "ooked it up, they nest on gravel roofs")
                        , previewMessage (previewMinutesAgo time 1596) (Id.fromInt 1) (NonemptyString 'o' "n roofs? that can't be comfortable")
                        ]
                    )
                )
          )
        , ( Id.fromInt 3
          , previewDmChannel
                [ previewMessage (previewMinutesAgo time 412) previewUserId (NonemptyString 't' "he backpack came out really well")
                , previewMessage (previewMinutesAgo time 396) (Id.fromInt 3) (NonemptyString 'i' " ran out of green halfway through but thank you")
                ]
                SeqDict.empty
          )
        ]


previewDiscordDmChannels :
    Time.Posix
    -> SeqDict.SeqDict (Discord.Id Discord.PrivateChannelId) DmChannel.DiscordFrontendDmChannel
previewDiscordDmChannels time =
    let
        messages : MessageArray ChannelMessageId (Discord.Id Discord.UserId)
        messages =
            List.foldl
                MessageArray.push
                MessageArray.empty
                [ previewMessage (previewMinutesAgo time 1523) previewOtherDiscordUserId (NonemptyString 'g' "g, that last round was rough")
                , previewMessage (previewMinutesAgo time 1519) previewDiscordUserId (NonemptyString 'r' "ematch after work tomorrow?")
                ]
    in
    SeqDict.singleton
        previewDiscordDmChannelId
        { messages = messages
        , visibleMessages = VisibleMessages.init True (MessageArray.length messages)
        , lastTypedAt = SeqDict.empty
        , members =
            NonemptyDict.singleton previewDiscordUserId { messagesSent = 1 }
                |> NonemptyDict.insert previewOtherDiscordUserId { messagesSent = 1 }
        , dateDividerDrawings = SeqDict.empty
        }


previewDiscordGuilds : Time.Posix -> SeqDict.SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
previewDiscordGuilds time =
    SeqDict.singleton
        previewDiscordGuildId
        { name = previewDiscordGuildName
        , icon = Just (FileStatus.fileHash "oZrA2YpsYOdRoJdkgHqQTNEpgNvznKNeSmwOeA")
        , channels = SeqDict.empty
        , membersAndOwner =
            MembersAndOwner.init
                (SeqDict.singleton
                    previewDiscordUserId
                    { joinedAt = Just time, roles = SeqSet.empty }
                )
                previewOtherDiscordUserId
        , stickers = SeqSet.empty
        , customEmojis = SeqSet.empty
        , roles = SeqDict.empty
        }


previewChannel : Time.Posix -> FrontendChannel
previewChannel time =
    let
        messages : MessageArray ChannelMessageId (Id UserId)
        messages =
            List.foldl
                MessageArray.push
                MessageArray.empty
                [ UserTextMessage
                    { createdAt = previewMinutesAgo time 1624
                    , createdBy = Id.fromInt 3
                    , content =
                        { content =
                            RichText.fromNonemptyString
                                Time.utc
                                SeqDict.empty
                                (NonemptyString 'h' "ere's that bird I drew, now on my backpack! [!1]")
                        , embeds = Array.empty
                        , attachedFiles =
                            SeqDict.fromList
                                [ ( Id.fromInt 1
                                  , { fileName = FileName.fromString "birb.webp"
                                    , fileSize = 71812
                                    , metadata =
                                        FileStatus.FileMetadata_Image
                                            { imageSize = Coord.xy 949 538
                                            , orientation = Nothing
                                            , gpsLocation = Nothing
                                            , cameraOwner = Nothing
                                            , exposureTime = Nothing
                                            , fNumber = Nothing
                                            , focalLength = Nothing
                                            , isoSpeedRating = Nothing
                                            , make = Nothing
                                            , model = Nothing
                                            , software = Nothing
                                            , userComment = Nothing
                                            }
                                            |> Just
                                    , contentType = FileStatus.webpContent
                                    , fileHash = FileStatus.fileHash "mnQelyTECkZW5RjIFCZjNirt8R_nuWGtV0WEzQ"
                                    , isEncrypted = IsNotEncrypted
                                    }
                                  )
                                ]
                        }
                    , reactions =
                        SeqDict.fromList
                            [ ( Emoji.EmojiOrCustomEmoji_Emoji Emoji.heart
                              , NonemptySet.singleton (Id.fromInt 1)
                              )
                            ]
                    , editedAt = Nothing
                    , repliedTo = NoReply
                    , drawings = Nothing
                    }
                , previewMessage (previewMinutesAgo time 1621) previewUserId (NonemptyString 'b' "ird!")
                , previewMessage (previewMinutesAgo time 1544) (Id.fromInt 2) (NonemptyString '_' "Once upon a midnight dreary while I pondered weak and weary_")
                , previewMessage (previewMinutesAgo time 1543) previewUserId (NonemptyString '#' "## *NO!*")
                , previewMessage (previewMinutesAgo time 1542) (Id.fromInt 2) (NonemptyString '_' "Over many a quaint and curious volume of forgotten lore_")
                , previewMessage (previewMinutesAgo time 1541) (Id.fromInt 2) (NonemptyString '_' "While I nodded, nearly napping, suddenly there came a tapping_")
                , previewMessage (previewMinutesAgo time 26) (Id.fromInt 3) (NonemptyString 't' "hat's not a raven!!")
                ]
    in
    { createdAt = previewMinutesAgo time 40000
    , createdBy = Id.fromInt 1
    , name = previewChannelName
    , description = ChannelDescription.empty
    , messages = messages
    , visibleMessages = VisibleMessages.init True (MessageArray.length messages)
    , isArchived = Nothing
    , lastTypedAt = SeqDict.fromList [ ( Id.fromInt 2, { time = time, messageIndex = Nothing } ) ]
    , threads =
        SeqDict.fromList
            [ ( Id.fromInt 0
              , previewThread
                    [ previewMessage (previewMinutesAgo time 1619) (Id.fromInt 1) (NonemptyString 'i' "s the strap hand sewn too?")
                    , previewMessage (previewMinutesAgo time 1616) (Id.fromInt 3) (NonemptyString 'e' "verything except the buckle")
                    ]
              )
            , ( Id.fromInt 2
              , previewThread
                    [ previewMessage (previewMinutesAgo time 1540) previewUserId (NonemptyString 'w' "e have talked about this")
                    , previewMessage (previewMinutesAgo time 1539) (Id.fromInt 2) (NonemptyString 'a' "nd yet")
                    , previewMessage (previewMinutesAgo time 31) (Id.fromInt 1) (NonemptyString 'i' " think it's nice actually")
                    ]
              )
            ]
    , dateDividerDrawings = SeqDict.empty
    , games = SeqDict.empty
    }


{-| The channel the word game is played in. The game card is the eighth message, which is what
`previewGameMatchId` names, and everything before it was said the evening before, so the
conversation carries a date divider above the card.
-}
previewGameChannel : Time.Posix -> FrontendChannel
previewGameChannel time =
    let
        messages : MessageArray ChannelMessageId (Id UserId)
        messages =
            List.foldl
                MessageArray.push
                MessageArray.empty
                [ previewMessage (previewMinutesAgo time 1268) (Id.fromInt 3) (NonemptyString 'a' "nyone up for a round tonight?")
                , previewMessage (previewMinutesAgo time 1264) (Id.fromInt 2) (NonemptyString 'i' "m in, give me until after dinner")
                , previewMessage (previewMinutesAgo time 1259) previewUserId (NonemptyString 's' "ame here")
                , previewMessage (previewMinutesAgo time 1251) (Id.fromInt 1) (NonemptyString 'i' "ll watch. I lose every one of these")
                , previewMessage (previewMinutesAgo time 1247) (Id.fromInt 2) (NonemptyString 'y' "ou lose because you only ever play four letter words")
                , previewMessage (previewMinutesAgo time 1245) (Id.fromInt 1) (NonemptyString 'f' "our letter words are words")
                , previewMessage (previewMinutesAgo time 1198) (Id.fromInt 3) (NonemptyString 'o' "k I'm falling asleep, tomorrow instead")
                , GameStarted
                    { startedAt = previewMinutesAgo time 8
                    , startedBy = Id.fromInt 3
                    , reactions = SeqDict.empty
                    , gameType = GameType_WordSpellingGame
                    , timestampDrawings = Drawing.emptyDrawing
                    , cardDrawings = Drawing.emptyDrawing
                    }
                , previewMessage (previewMinutesAgo time 5) (Id.fromInt 2) (NonemptyString 'h' "ow do you get a Q and a Z in the same tray")
                , previewMessage (previewMinutesAgo time 3) previewUserId (NonemptyString 'c' "lean living")
                ]
    in
    { createdAt = previewMinutesAgo time 60000
    , createdBy = Id.fromInt 1
    , name = previewChannelName
    , description = ChannelDescription.empty
    , messages = messages
    , visibleMessages = VisibleMessages.init True (MessageArray.length messages)
    , isArchived = Nothing
    , lastTypedAt = SeqDict.fromList [ ( Id.fromInt 3, { time = time, messageIndex = Nothing } ) ]
    , threads = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , games = previewGames time
    }


previewGuild : Time.Posix -> FrontendGuild
previewGuild time =
    { createdAt = previewMinutesAgo time 40000
    , createdBy = Id.fromInt 1
    , name = previewGuildName
    , icon = Just (FileStatus.fileHash "c_fknEBFP2Tbqh4_2NcGxm7qHXm8lRZfOpXfzg")
    , channels =
        SeqDict.fromList
            [ ( previewChannelId, previewChannel time )
            , ( Id.fromInt 1
              , { createdAt = previewMinutesAgo time 39000
                , createdBy = Id.fromInt 1
                , name = petPicsChannelName
                , description = ChannelDescription.empty
                , messages = MessageArray.empty
                , visibleMessages = VisibleMessages.init True 0
                , isArchived = Nothing
                , lastTypedAt = SeqDict.empty
                , threads = SeqDict.empty
                , dateDividerDrawings = SeqDict.empty
                , games = SeqDict.empty
                }
              )
            ]
    , membersAndOwner =
        MembersAndOwner.init
            (SeqDict.map (\_ _ -> { joinedAt = previewMinutesAgo time 39500 }) previewOtherUsers
                |> SeqDict.insert previewUserId { joinedAt = previewMinutesAgo time 39500 }
            )
            (Id.fromInt 1)
    , invites = SeqDict.empty
    }


previewGameGuild : Time.Posix -> FrontendGuild
previewGameGuild time =
    { createdAt = previewMinutesAgo time 60000
    , createdBy = Id.fromInt 1
    , name = previewGameGuildName
    , icon = Just (FileStatus.fileHash "OW5CQBd1c1K1WO7VYOsgq8BL6Fimp-EE2e141g")
    , channels =
        SeqDict.fromList
            [ ( previewChannelId, previewGameChannel time )
            , ( Id.fromInt 1
              , { createdAt = previewMinutesAgo time 59000
                , createdBy = Id.fromInt 1
                , name = petPicsChannelName
                , description = ChannelDescription.empty
                , messages = MessageArray.empty
                , visibleMessages = VisibleMessages.init True 0
                , isArchived = Nothing
                , lastTypedAt = SeqDict.empty
                , threads = SeqDict.empty
                , dateDividerDrawings = SeqDict.empty
                , games = SeqDict.empty
                }
              )
            ]
    , membersAndOwner =
        MembersAndOwner.init
            (SeqDict.map (\_ _ -> { joinedAt = previewMinutesAgo time 59500 }) previewOtherUsers
                |> SeqDict.insert previewUserId { joinedAt = previewMinutesAgo time 59500 }
            )
            (Id.fromInt 1)
    , invites = SeqDict.empty
    }


previewLoginData : Time.Posix -> UserAgent -> LoginData
previewLoginData time userAgent =
    { session =
        { userId = previewUserId
        , notificationMode = UserSession.NoNotifications
        , pushSubscription = UserSession.NotSubscribed
        , userAgent = userAgent
        , sessionIdHash = SessionIdHash.fromString ""
        , signedInAt = previewMinutesAgo time 120
        , lastClientDisconnect = Nothing
        , expandedUserOptions = SeqSet.empty
        , savedSheepGameQuestions = IdArray.empty
        }
    , currentlyViewing = Viewing_None
    , adminData = IsNotAdminLoginData
    , twoFactorAuthenticationEnabled = Nothing
    , guilds =
        SeqDict.fromList
            [ ( previewGuildId, previewGuild time )
            , ( previewGameGuildId, previewGameGuild time )
            ]
    , dmChannels = previewDmChannels time
    , discordDmChannels = previewDiscordDmChannels time
    , discordGuilds = previewDiscordGuilds time
    , user = previewUser
    , otherUsers = previewOtherUsers
    , discordUsers = previewDiscordUsers
    , otherSessions = SeqDict.empty
    , publicVapidKey = ""
    , textEditor = TextEditor.initLocalState
    , stickers = SeqDict.empty
    , customEmojis = SeqDict.empty
    , voiceChatPeers = SeqDict.empty
    }


{-| The unread overview preview is of an inbox with nothing in it, so this reader has caught up
with every channel, DM and thread rather than stopping partway like `previewUser` does.
-}
previewReadLoginData : Time.Posix -> UserAgent -> LoginData
previewReadLoginData time userAgent =
    let
        loginData : LoginData
        loginData =
            previewLoginData time userAgent

        user : BackendUser
        user =
            loginData.user

        lastViewed : List ( key, Int ) -> SeqDict.SeqDict key (Id messageId)
        lastViewed messageCounts =
            List.foldl
                (\( key, messageCount ) acc ->
                    if messageCount == 0 then
                        acc

                    else
                        SeqDict.insert key (Id.fromInt (messageCount - 1)) acc
                )
                SeqDict.empty
                messageCounts

        channelMessageCounts : List ( AnyGuildOrDmId, Int )
        channelMessageCounts =
            List.concatMap
                (\( guildId, guild ) ->
                    List.map
                        (\( channelId, channel ) ->
                            ( GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                            , MessageArray.length channel.messages
                            )
                        )
                        (SeqDict.toList guild.channels)
                )
                (SeqDict.toList loginData.guilds)
                ++ List.map
                    (\( otherUserId, dmChannel ) ->
                        ( GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId })
                        , MessageArray.length dmChannel.messages
                        )
                    )
                    (SeqDict.toList loginData.dmChannels)
                ++ List.map
                    (\( channelId, dmChannel ) ->
                        ( DiscordGuildOrDmId
                            (DiscordGuildOrDmId_Dm
                                { currentUserId = previewDiscordUserId, channelId = channelId }
                            )
                        , MessageArray.length dmChannel.messages
                        )
                    )
                    (SeqDict.toList loginData.discordDmChannels)

        threadMessageCounts : List ( ( AnyGuildOrDmId, Id ChannelMessageId ), Int )
        threadMessageCounts =
            List.concatMap
                (\( guildId, guild ) ->
                    List.concatMap
                        (\( channelId, channel ) ->
                            List.map
                                (\( threadId, thread ) ->
                                    ( ( GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                                      , threadId
                                      )
                                    , MessageArray.length thread.messages
                                    )
                                )
                                (SeqDict.toList channel.threads)
                        )
                        (SeqDict.toList guild.channels)
                )
                (SeqDict.toList loginData.guilds)
                ++ List.concatMap
                    (\( otherUserId, dmChannel ) ->
                        List.map
                            (\( threadId, thread ) ->
                                ( ( GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId }), threadId )
                                , MessageArray.length thread.messages
                                )
                            )
                            (SeqDict.toList dmChannel.threads)
                    )
                    (SeqDict.toList loginData.dmChannels)
    in
    { loginData
        | user =
            { user
                | lastViewedMessage = lastViewed channelMessageCounts
                , lastViewedThreadMessage = lastViewed threadMessageCounts
            }
    }


previewGameMatchId : Id ChannelMessageId
previewGameMatchId =
    Id.fromInt 7


previewGameSetup : Result String WordSpellingGame.ValidatedSetup
previewGameSetup =
    WordSpellingGame.validateSetup previewUserId (Time.millisToPosix 0) WordSpellingGame.initSetup


previewGameLetters : Char -> String -> Nonempty LetterOrWildcard
previewGameLetters first rest =
    Nonempty
        (Letter (LetterChar first))
        (List.map (\char -> Letter (LetterChar char)) (String.toList rest))


{-| A move in the preview match. `secondsAgo` is counted back from the current time on every
render, so the clocks always read the same however long the page has been open.
-}
previewGameMove : Time.Posix -> Float -> Id UserId -> ( Int, Int ) -> Bool -> Nonempty LetterOrWildcard -> ActionWithTime
previewGameMove time secondsAgo userId start isVertical letters =
    { userId = userId
    , time = Duration.addTo time (Duration.seconds -secondsAgo)
    , change =
        PlaceWord
            { start = start, isVertical = isVertical, letters = letters }
            (FilledInByBackend (IsValid Set.empty))
    }


{-| The letters already on the board carry on past `start`, so each move only lists the tiles it
adds: ZEBRA starts on the Z that QUARTZ left behind and places E, B, R and A below it.

Both joins happen before the first word, because a player can only join while the turn count
hasn't passed the number of players. The three then take turns in the order they joined, and the
match is left on Sven's turn so the preview has a tray to show.

-}
previewGameActions : Time.Posix -> Array ActionWithTime
previewGameActions time =
    Array.fromList
        [ { userId = Id.fromInt 2, time = Duration.addTo time (Duration.seconds -430), change = JoinGame }
        , { userId = Id.fromInt 3, time = Duration.addTo time (Duration.seconds -420), change = JoinGame }
        , previewGameMove time 360 previewUserId ( 4, 7 ) False (previewGameLetters 'Q' "UARTZ")
        , { userId = Id.fromInt 3
          , time = Duration.addTo time (Duration.seconds -350)
          , change =
                -- Move 3 is QUARTZ: the two joins take the first two rows of the Moves log.
                AddedReaction (MoveReaction 3) (Emoji.EmojiOrCustomEmoji_Emoji (Emoji.fromString "🔥"))
          }
        , previewGameMove time 300 (Id.fromInt 2) ( 9, 7 ) True (previewGameLetters 'E' "BRA")
        , previewGameMove time 240 (Id.fromInt 3) ( 9, 9 ) False (previewGameLetters 'R' "INK")
        , previewGameMove time 180 previewUserId ( 6, 7 ) True (previewGameLetters 'X' "E")
        , previewGameMove time 120 (Id.fromInt 2) ( 9, 11 ) False (previewGameLetters 'G' "ILE")
        , previewGameMove time 60 (Id.fromInt 3) ( 10, 11 ) True (previewGameLetters 'U' "ST")
        ]


previewGameShared : Time.Posix -> WordSpellingGame.ValidatedSetup -> WordSpellingGame.Shared
previewGameShared time setup =
    Array.foldl
        (\action shared -> WordSpellingGame.updateAction setup action shared |> Tuple.first)
        (WordSpellingGame.initShared setup)
        (previewGameActions time)


previewGames : Time.Posix -> SeqDict.SeqDict (Id ChannelMessageId) Game.MatchData
previewGames time =
    case previewGameSetup of
        Ok setup ->
            SeqDict.singleton
                previewGameMatchId
                (Game.initMatchData
                    (Game.GameData_WordSpellingGame setup (previewGameActions time) (previewGameShared time setup))
                    Nothing
                )

        Err _ ->
            SeqDict.empty


previewGameModels : Time.Posix -> SeqDict.SeqDict GuildOrDmId Game.Model
previewGameModels time =
    case previewGameSetup of
        Ok setup ->
            let
                gameModel : Game.Model
                gameModel =
                    Game.initModel
            in
            SeqDict.singleton
                (GuildOrDmId_Guild { guildId = previewGameGuildId, channelId = previewChannelId })
                { gameModel
                    | startedGames =
                        -- The tray tiles animate in over the second after the game model is built,
                        -- so build it in the past: `time` advances every second and the tiles would
                        -- otherwise be stuck at the start of that animation, leaving the tray empty.
                        WordSpellingGame.initGame
                            (Duration.addTo time (Duration.seconds -10))
                            previewUserId
                            setup
                            (previewGameShared time setup)
                            |> Game.WordSpellingGame_Game
                            |> SeqDict.singleton previewGameMatchId
                }

        Err _ ->
            SeqDict.empty


{-| A page of the app the carousel shows.
-}
type PreviewPage
    = PreviewChannel (Id GuildId) Route.ChannelRoute
    | PreviewUnreadOverview


previewPages : List PreviewPage
previewPages =
    (PreviewChannel
        previewGuildId
        (Route.ChannelRoute previewChannelId (Route.NoThreadWithFriends Nothing Route.HideChannelSettings) Nothing)
        :: (case previewGameSetup of
                Ok _ ->
                    [ PreviewChannel
                        previewGameGuildId
                        (Route.ChannelRoute
                            previewChannelId
                            (Route.NoThreadWithFriends Nothing Route.HideChannelSettings)
                            (Just (ChannelHeaderTab_Games (Just previewGameMatchId) Nothing))
                        )
                    ]

                Err _ ->
                    []
           )
    )
        ++ [ PreviewUnreadOverview ]


previewIntervalMillis : Int
previewIntervalMillis =
    6000


activePreview : LoadedFrontend -> Int
activePreview loaded =
    if loaded.homePagePreview.rotate then
        let
            elapsed : Int
            elapsed =
                Time.posixToMillis loaded.time - Time.posixToMillis loaded.homePagePreview.changedAt |> max 0
        in
        loaded.homePagePreview.index
            + (elapsed // previewIntervalMillis)
            |> modBy (List.length previewPages)

    else
        loaded.homePagePreview.index


previousPreviewButton : Int -> Element FrontendMsg_
previousPreviewButton activeIndex =
    MyUi.elButton
        (Dom.id "homePage_previousPreview")
        (PressedHomePagePreview (modBy (List.length previewPages) (activeIndex - 1)))
        [ Ui.alignLeft, Ui.width (Ui.px 64), Ui.height Ui.fill ]
        Ui.none


nextPreviewButton : Int -> Element FrontendMsg_
nextPreviewButton activeIndex =
    MyUi.elButton
        (Dom.id "homePage_nextPreview")
        (PressedHomePagePreview (modBy (List.length previewPages) (activeIndex + 1)))
        [ Ui.alignRight, Ui.width (Ui.px 64), Ui.height Ui.fill ]
        Ui.none


previewDots : Int -> Element FrontendMsg_
previewDots activeIndex =
    List.range 0 (List.length previewPages - 1)
        |> List.map
            (\index ->
                MyUi.elButton
                    (Dom.id ("homePage_preview_" ++ String.fromInt index))
                    (PressedHomePagePreview index)
                    [ Ui.padding 8
                    ]
                    (Ui.el
                        [ Ui.width (Ui.px 12)
                        , Ui.height (Ui.px 12)
                        , Ui.rounded 99
                        , Ui.background
                            (if index == activeIndex then
                                MyUi.white

                             else
                                Ui.rgba 255 255 255 0.4
                            )
                        ]
                        Ui.none
                    )
            )
        |> Ui.row [ Ui.width Ui.shrink, Ui.centerX ]


view : LoadedFrontend -> Element FrontendMsg_
view loaded =
    let
        previewLoggedIn : Types.LoggedIn2
        previewLoggedIn =
            FrontendExtra.loadedInitHelper
                loaded.startupData
                loaded.emojiData
                (previewLoginData loaded.time loaded.startupData.userAgent)
                loaded
                |> Tuple.first

        widthMax : Int
        widthMax =
            1280

        paddingX : Int
        paddingX =
            if Coord.xRaw loaded.windowSize < 800 then
                24

            else
                48

        isMobile : Bool
        isMobile =
            MyUi.isMobile loaded

        previewWidth : Int
        previewWidth =
            min (Coord.xRaw loaded.windowSize) widthMax - paddingX * 2

        previewHeight : Int
        previewHeight =
            if isMobile then
                600

            else
                850

        previewScale : Float
        previewScale =
            if isMobile then
                0.8

            else
                1

        innerSize : Coord CssPixels
        innerSize =
            Coord.xy
                (round (toFloat previewWidth / previewScale))
                (round (toFloat previewHeight / previewScale))

        activeIndex : Int
        activeIndex =
            activePreview loaded

        previewReadLoggedIn : Types.LoggedIn2
        previewReadLoggedIn =
            FrontendExtra.loadedInitHelper
                loaded.startupData
                loaded.emojiData
                (previewReadLoginData loaded.time loaded.startupData.userAgent)
                loaded
                |> Tuple.first

        slide : PreviewPage -> Element FrontendMsg_
        slide page =
            (case page of
                PreviewChannel guildId slideRoute ->
                    Pages.Guild.guildView
                        { loaded
                            | windowSize = innerSize
                            , route = GuildRoute guildId slideRoute ChannelsVisibleOnMobile Nothing
                        }
                        guildId
                        slideRoute
                        { previewLoggedIn
                            | sidebarMode = ChannelSidebarNotDragging { offset = 1 }
                            , games = previewGameModels loaded.time
                        }
                        (Local.model previewLoggedIn.localState)

                PreviewUnreadOverview ->
                    Pages.Guild.homePageLoggedInView
                        Pages.Guild.NoDmChannelSelected
                        { loaded
                            | windowSize = innerSize
                            , route = HomePageRoute Nothing
                        }
                        { previewReadLoggedIn | sidebarMode = ChannelSidebarNotDragging { offset = 1 } }
                        (Local.model previewReadLoggedIn.localState)
            )
                |> Ui.el
                    [ Ui.width (Ui.px (Coord.xRaw innerSize))
                    , Ui.height (Ui.px (Coord.yRaw innerSize))
                    , -- Without this the app inside is laid out at its natural height, since elm-ui
                      -- leaves min-height at min-content and that wins over the height above.
                      Ui.heightMin 0
                    , MyUi.htmlStyle "transform" ("scale(" ++ String.fromFloat previewScale ++ ")")
                    , MyUi.htmlStyle "transform-origin" "top left"
                    ]
                |> Ui.el
                    [ Ui.width (Ui.px previewWidth)
                    , Ui.height (Ui.px previewHeight)
                    , Ui.heightMin 0
                    , Ui.clip
                    , MyUi.noShrinking
                    ]
    in
    Ui.column
        [ MyUi.notoSans
        , Ui.paddingWith
            { left = paddingX
            , right = paddingX
            , top =
                if isMobile then
                    80

                else
                    120
            , bottom = 48
            }
        , Ui.widthMax widthMax
        , Ui.centerX
        , if isMobile then
            Ui.spacing 16

          else
            Ui.spacing 32
        ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text "at-chat, a place to chat with friends")
        , Ui.column
            [ Ui.spacing 12 ]
            [ List.map slide previewPages
                |> Ui.row
                    [ Ui.width (Ui.px (previewWidth * List.length previewPages))
                    , Ui.height (Ui.px previewHeight)
                    , Ui.heightMin 0
                    , MyUi.noPointerEvents
                    , Ui.move { x = -activeIndex * previewWidth, y = 0, z = 0 }
                    , -- Ui.move sets the css translate property, so this animates the slide
                      -- across rather than jumping to it.
                      MyUi.htmlStyle "transition" "translate 300ms ease-out"
                    ]
                |> Ui.el
                    ([ Ui.width (Ui.px previewWidth)
                     , Ui.height (Ui.px previewHeight)
                     , Ui.heightMin 0
                     , Ui.clip
                     , Ui.Shadow.shadows [ { x = 0, y = 0, blur = 10, size = 0, color = Ui.rgba 255 255 255 0.5 } ]
                     ]
                        ++ (if List.length previewPages > 1 then
                                [ Ui.inFront (previousPreviewButton activeIndex)
                                , Ui.inFront (nextPreviewButton activeIndex)
                                ]

                            else
                                []
                           )
                    )
            , if List.length previewPages > 1 then
                previewDots activeIndex

              else
                Ui.none
            ]
        ]
