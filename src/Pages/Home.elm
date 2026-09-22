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
import SafeFloat exposing (SafeFloat)
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


{-| Wraps the carousel so that `MyUi.css` can lay the conversations inside it out from the
bottom. Each slide is a whole copy of the app, so several of them carry the one conversation
container id and only the first could be found and scrolled.
-}
previewContainerId : HtmlId
previewContainerId =
    Dom.id "homePage_preview"


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
                  , Id.fromInt 6
                  )
                , ( GuildOrDmId (GuildOrDmId_Dm { otherUserId = Id.fromInt 1 })
                  , Id.fromInt 5
                  )
                ]
        , lastViewedThreadMessage =
            SeqDict.fromList
                [ ( ( GuildOrDmId
                        (GuildOrDmId_Guild
                            { guildId = previewGuildId
                            , channelId = previewChannelId
                            }
                        )
                    , Id.fromInt 0
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
                [ previewMessage (previewMinutesAgo time 20000) previewUserId (NonemptyString 'I' " watched an old western yesterday, it was decent")
                , UserTextMessage
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
                , UserTextMessage
                    { createdAt = previewMinutesAgo time 1621
                    , createdBy = previewUserId
                    , content =
                        { content = RichText.fromNonemptyString Time.utc SeqDict.empty (NonemptyString 'b' "ird!")
                        , embeds = Array.empty
                        , attachedFiles = SeqDict.empty
                        }
                    , reactions = SeqDict.empty
                    , editedAt = Nothing
                    , repliedTo = NoReply
                    , drawings = Just previewDoodles
                    }
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
            [ ( Id.fromInt 0, previewThread [ previewMessage (previewMinutesAgo time 1621) previewUserId (NonemptyString 'b' "") ] )
            , ( Id.fromInt 6
              , List.repeat 104 (previewMessage (previewMinutesAgo time 1540) previewUserId (NonemptyString 'a' ""))
                    ++ [ previewMessage (previewMinutesAgo time 31) (Id.fromInt 1) (NonemptyString 'S' "hall be lifted—nevermore!") ]
                    |> previewThread
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
            (SeqDict.map (\_ _ -> { joinedAt = previewMinutesAgo time 39500, lastPostedAt = Nothing }) previewOtherUsers
                |> SeqDict.insert previewUserId { joinedAt = previewMinutesAgo time 39500, lastPostedAt = Nothing }
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
            (SeqDict.map (\_ _ -> { joinedAt = previewMinutesAgo time 59500, lastPostedAt = Nothing }) previewOtherUsers
                |> SeqDict.insert previewUserId { joinedAt = previewMinutesAgo time 59500, lastPostedAt = Nothing }
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


previewGameActions : Time.Posix -> Array ActionWithTime
previewGameActions time =
    Array.fromList
        [ { userId = Id.fromInt 2, time = Duration.addTo time (Duration.seconds -430), change = JoinGame }
        , { userId = Id.fromInt 3, time = Duration.addTo time (Duration.seconds -420), change = JoinGame }
        , previewGameMove time 360 previewUserId ( 4, 7 ) False (previewGameLetters 'Q' "UARTZ")
        , { userId = Id.fromInt 3
          , time = Duration.addTo time (Duration.seconds -350)
          , change =
                AddedReaction (MoveReaction 3) (Emoji.EmojiOrCustomEmoji_Emoji (Emoji.fromString "🔥"))
          }
        , { userId = Id.fromInt 3
          , time = Duration.addTo time (Duration.seconds -350)
          , change =
                AddedReaction (MoveReaction 3) (Emoji.EmojiOrCustomEmoji_Emoji (Emoji.fromString "💎"))
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
    8000


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


{-| The preview is of one fixed moment rather than the current one, so that its clocks and
date dividers don't move and the whole of it doesn't re-render every second.
-}
previewTime : Time.Posix
previewTime =
    Time.millisToPosix 1790023692000


view : LoadedFrontend -> Element FrontendMsg_
view loaded =
    let
        previewLoggedIn : Types.LoggedIn2
        previewLoggedIn =
            FrontendExtra.loadedInitHelper
                loaded.startupData
                loaded.emojiData
                (previewLoginData previewTime loaded.startupData.userAgent)
                loaded
                |> Tuple.first

        widthMax : Int
        widthMax =
            1280

        paddingX : Int
        paddingX =
            if isMobile then
                16

            else if Coord.xRaw loaded.windowSize < 800 then
                24

            else
                48

        isMobile : Bool
        isMobile =
            MyUi.isMobile loaded

        previewWidth : Int
        previewWidth =
            min (Coord.xRaw loaded.windowSize) widthMax - paddingX * 2

        topPadding : Int
        topPadding =
            if isMobile then
                80

            else
                120

        bottomPadding : Int
        bottomPadding =
            48

        headingSpacing : Int
        headingSpacing =
            if isMobile then
                16

            else
                32

        headingHeight : Int
        headingHeight =
            30

        dotsSpacing : Int
        dotsSpacing =
            12

        dotsHeight : Int
        dotsHeight =
            28

        -- How tall the app inside the preview is laid out, before it's scaled to fit the box
        previewContentHeight : Int
        previewContentHeight =
            if isMobile then
                750

            else
                850

        previewHeight : Int
        previewHeight =
            Coord.yRaw loaded.windowSize
                - (topPadding + headingHeight + headingSpacing + dotsSpacing + dotsHeight + bottomPadding)
                |> min
                    (if isMobile then
                        600

                     else
                        850
                    )
                |> max 200

        -- The preview shows the whole of the app it's laid out as however short the window is,
        -- by shrinking to the room left below the heading rather than running off the bottom
        -- of the page
        previewScale : Float
        previewScale =
            toFloat previewHeight / toFloat previewContentHeight

        innerSize : Coord CssPixels
        innerSize =
            Coord.xy (round (toFloat previewWidth / previewScale)) previewContentHeight

        activeIndex : Int
        activeIndex =
            activePreview loaded

        previewReadLoggedIn : Types.LoggedIn2
        previewReadLoggedIn =
            FrontendExtra.loadedInitHelper
                loaded.startupData
                loaded.emojiData
                (previewReadLoginData previewTime loaded.startupData.userAgent)
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
                            , time = previewTime
                        }
                        guildId
                        slideRoute
                        { previewLoggedIn
                            | sidebarMode = ChannelSidebarNotDragging { offset = 1 }
                            , games = previewGameModels previewTime
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
            , top = topPadding
            , bottom = bottomPadding
            }
        , Ui.widthMax widthMax
        , Ui.centerX
        , Ui.spacing headingSpacing
        ]
        [ Ui.el
            [ Ui.Font.size
                (if isMobile then
                    20

                 else
                    24
                )
            , Ui.attrIf isMobile Ui.contentCenterX
            ]
            (Ui.text "at-chat, a place to chat with friends")
        , Ui.column
            [ Ui.spacing dotsSpacing ]
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
                    ([ Ui.id (Dom.idToString previewContainerId)
                     , Ui.width (Ui.px previewWidth)
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


{-| A doodle Martin drew over the "bird!" message and exported out of the real app. The points
are css pixels relative to the top left of the message's timestamp, which is why they're mostly
to the left of it and reach down over the messages below. They're simplified from the export,
which recorded a point every few hundredths of a pixel.
-}
previewDoodles : Message.UserTextMessageDrawings (Id UserId)
previewDoodles =
    { timestampDrawings =
        { finished =
            [ previewDoodleStroke previewUserId
                ( -336.3, 131.8 )
                [ ( -302.7, 131.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -389.7, 139.5 )
                [ ( -388.7, 136.5 )
                , ( -388.3, 127.5 )
                , ( -388, 94.1 )
                , ( -383.3, 83.5 )
                , ( -379.3, 76.8 )
                , ( -377.3, 75.5 )
                , ( -372.3, 74.5 )
                , ( -371, 73.5 )
                , ( -367.3, 72.8 )
                , ( -339.7, 72.8 )
                , ( -336.3, 72.1 )
                , ( -330.7, 72.8 )
                , ( -317.7, 72.8 )
                , ( -309.7, 74.5 )
                , ( -299.7, 74.5 )
                , ( -291.7, 72.8 )
                , ( -273.3, 72.8 )
                , ( -265.3, 78.1 )
                , ( -262, 85.1 )
                , ( -261.7, 113.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -390.3, 146.8 )
                [ ( -390.7, 207.5 )
                , ( -390, 216.5 )
                , ( -387, 224.5 )
                , ( -381, 231.8 )
                , ( -376.3, 234.8 )
                , ( -359.3, 238.8 )
                , ( -306, 238.8 )
                , ( -300, 239.1 )
                , ( -292, 240.8 )
                , ( -280.7, 240.8 )
                , ( -276.3, 240.1 )
                , ( -270, 237.8 )
                , ( -266, 234.8 )
                , ( -262.7, 229.8 )
                , ( -262.7, 217.8 )
                , ( -264, 209.1 )
                , ( -264, 176.1 )
                , ( -264.7, 172.1 )
                , ( -264.3, 148.8 )
                , ( -265.3, 143.1 )
                , ( -265.3, 137.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -298.3, 211.1 )
                [ ( -302.3, 211.8 )
                , ( -334, 211.8 )
                , ( -343.7, 212.8 )
                , ( -347.7, 214.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -336.7, 195.1 )
                [ ( -339.3, 199.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -323, 193.8 )
                [ ( -326, 197.1 )
                , ( -327, 199.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -309.7, 192.5 )
                [ ( -313.7, 200.1 )
                , ( -314, 200.5 )
                , ( -314.7, 199.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -299, 188.5 )
                [ ( -298.7, 194.1 )
                , ( -299.7, 196.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -314, 142.1 )
                [ ( -311.3, 145.5 )
                , ( -306.7, 156.1 )
                , ( -305.3, 178.1 )
                , ( -307.3, 179.1 )
                , ( -313, 179.1 )
                , ( -324.3, 181.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -267.3, 109.8 )
                [ ( -262, 113.1 )
                , ( -258.3, 119.1 )
                , ( -255.7, 126.1 )
                , ( -256.3, 142.8 )
                , ( -258, 148.8 )
                , ( -258.7, 145.1 )
                , ( -261, 140.1 )
                , ( -267.3, 131.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -344.7, 108.5 )
                [ ( -347.7, 115.1 )
                , ( -347.7, 116.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -332.3, 108.5 )
                [ ( -333.7, 110.5 )
                , ( -337.3, 113.1 )
                , ( -339, 115.8 )
                , ( -339, 118.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -323, 112.8 )
                [ ( -325.7, 115.8 )
                , ( -327.3, 120.8 )
                , ( -327.3, 127.1 )
                , ( -326.7, 128.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -310.7, 110.1 )
                [ ( -315.7, 112.1 )
                , ( -319.7, 117.5 )
                , ( -321.3, 122.1 )
                , ( -322, 125.8 )
                , ( -321.7, 127.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -297.7, 106.5 )
                [ ( -305.7, 114.8 )
                , ( -308.3, 119.1 )
                , ( -307.7, 121.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -274.3, 124.5 )
                [ ( -285.3, 124.5 )
                , ( -294.3, 128.1 )
                , ( -298, 131.1 )
                , ( -299.3, 133.1 )
                , ( -301.7, 139.5 )
                , ( -302.3, 149.8 )
                , ( -301.3, 152.5 )
                , ( -299.7, 154.5 )
                , ( -298.3, 155.5 )
                , ( -292.7, 156.5 )
                , ( -282, 156.5 )
                , ( -274.7, 152.1 )
                , ( -269.3, 144.5 )
                , ( -267.7, 139.5 )
                , ( -267.7, 133.8 )
                , ( -271, 127.8 )
                , ( -275.7, 125.1 )
                , ( -277, 125.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -364.7, 123.5 )
                [ ( -374, 126.1 )
                , ( -383.7, 134.1 )
                , ( -386.7, 135.8 )
                , ( -394.3, 150.8 )
                , ( -394.3, 156.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -348.3, 125.1 )
                [ ( -345, 126.1 )
                , ( -337, 131.8 )
                , ( -335, 135.5 )
                , ( -334.3, 140.1 )
                , ( -335.7, 146.1 )
                , ( -340, 153.1 )
                , ( -341, 154.5 )
                , ( -346, 157.5 )
                , ( -353.7, 157.8 )
                , ( -362.3, 156.8 )
                , ( -365.3, 155.5 )
                , ( -368, 149.5 )
                , ( -369.7, 142.8 )
                , ( -370, 132.1 )
                , ( -367.3, 127.1 )
                , ( -365.3, 125.1 )
                , ( -362.3, 123.5 )
                , ( -355.7, 122.5 )
                , ( -348, 122.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -15, 231.5 )
                [ ( -23.7, 225.8 )
                , ( -25.7, 223.8 )
                , ( -26.7, 221.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -25, 241.5 )
                [ ( -17.7, 234.5 )
                , ( -15.3, 231.1 )
                ]
            , previewDoodleStroke previewUserId
                ( 7.7, 235.5 )
                [ ( 5.3, 231.5 )
                , ( -4.3, 219.5 )
                , ( -28.3, 199.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -12, 256.1 )
                [ ( -5.3, 246.8 )
                , ( -1.7, 243.5 )
                , ( 5, 239.5 )
                , ( 6, 237.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -23.7, 245.1 )
                [ ( -28.3, 245.1 )
                , ( -33.7, 247.5 )
                , ( -35, 248.8 )
                , ( -35, 254.1 )
                , ( -34.3, 257.5 )
                , ( -33, 261.1 )
                , ( -30.7, 264.1 )
                , ( -26.7, 266.1 )
                , ( -20.3, 266.1 )
                , ( -16.3, 265.5 )
                , ( -14, 264.1 )
                , ( -12, 261.5 )
                , ( -12, 257.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -37.3, 192.5 )
                [ ( -35, 196.1 )
                , ( -33, 202.5 )
                , ( -29.7, 218.1 )
                , ( -29.7, 226.1 )
                , ( -33.3, 251.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -118, 212.1 )
                [ ( -121.3, 222.1 )
                , ( -122, 230.1 )
                , ( -120.7, 239.8 )
                , ( -116.7, 254.5 )
                , ( -116.3, 260.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -172.3, 228.8 )
                [ ( -177.7, 230.8 )
                , ( -191.3, 233.1 )
                , ( -194.7, 234.8 )
                , ( -194.3, 238.1 )
                , ( -188.3, 242.8 )
                , ( -185, 244.5 )
                , ( -181, 245.5 )
                , ( -168.3, 243.8 )
                , ( -166.3, 243.1 )
                , ( -159, 238.5 )
                , ( -158, 236.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -175, 216.5 )
                [ ( -191.3, 217.8 )
                , ( -194.3, 219.1 )
                , ( -195, 221.5 )
                , ( -193.3, 225.1 )
                , ( -189, 228.1 )
                , ( -180, 228.5 )
                , ( -174, 230.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -172, 199.8 )
                [ ( -190.7, 198.1 )
                , ( -195.3, 198.8 )
                , ( -197.7, 200.1 )
                , ( -198.3, 205.1 )
                , ( -193.7, 212.8 )
                , ( -189.7, 214.5 )
                , ( -182.7, 214.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -193.7, 159.1 )
                [ ( -193.7, 182.5 )
                , ( -191.3, 194.1 )
                , ( -189.3, 196.5 )
                , ( -189, 197.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -177, 159.5 )
                [ ( -178.3, 156.8 )
                , ( -180.7, 154.5 )
                , ( -187.3, 154.8 )
                , ( -193.7, 158.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -162.3, 187.1 )
                [ ( -166, 184.1 )
                , ( -168.7, 180.8 )
                , ( -170, 176.5 )
                , ( -174.3, 168.5 )
                , ( -176.3, 158.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -117.3, 210.8 )
                [ ( -143.3, 228.5 )
                , ( -158.3, 236.1 )
                , ( -161, 236.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -116.3, 196.5 )
                [ ( -162.7, 187.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -82.7, 190.1 )
                [ ( -81, 193.8 )
                , ( -78.3, 195.8 )
                , ( -67.7, 197.5 )
                , ( -62, 196.8 )
                , ( -60, 190.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -133.7, 180.5 )
                [ ( -133.3, 180.8 )
                , ( -131.3, 178.1 )
                , ( -125, 172.8 )
                , ( -123.7, 172.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -133.3, 132.8 )
                [ ( -137, 139.8 )
                , ( -139.3, 151.1 )
                , ( -139.3, 163.5 )
                , ( -136.7, 173.5 )
                , ( -136.7, 175.5 )
                , ( -135.3, 177.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -142, 133.1 )
                [ ( -136, 130.1 )
                , ( -131, 129.1 )
                , ( -123.3, 129.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -92, 105.8 )
                [ ( -100.3, 106.5 )
                , ( -119.3, 111.5 )
                , ( -126, 114.5 )
                , ( -130.7, 116.8 )
                , ( -138.7, 122.5 )
                , ( -142, 126.8 )
                , ( -142.7, 130.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -91.3, 104.8 )
                [ ( -86, 97.1 )
                , ( -85.3, 92.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -12.3, 121.8 )
                [ ( -14.3, 118.1 )
                , ( -17.3, 115.1 )
                , ( -30, 109.5 )
                , ( -38.3, 107.1 )
                , ( -50, 104.8 )
                , ( -61, 103.5 )
                , ( -74.7, 103.5 )
                , ( -85.7, 105.1 )
                , ( -90.7, 105.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -38, 120.8 )
                [ ( -35.3, 122.5 )
                , ( -31.3, 123.8 )
                , ( -23, 123.8 )
                , ( -13, 122.1 )
                ]
            , previewDoodleStroke previewUserId
                ( 10.7, 195.1 )
                [ ( 3.3, 184.1 )
                , ( -3, 176.1 )
                , ( -12.3, 161.5 )
                , ( -19.3, 146.5 )
                , ( -27, 124.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -22.7, 185.1 )
                [ ( -15.3, 189.8 )
                , ( -10.3, 191.8 )
                , ( 1.7, 195.8 )
                , ( 8, 197.1 )
                , ( 10.3, 196.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -22, 198.1 )
                [ ( -23, 185.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -33, 184.5 )
                [ ( -27.7, 191.5 )
                , ( -25, 196.5 )
                , ( -23.7, 197.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -45.7, 192.1 )
                [ ( -38.7, 190.5 )
                , ( -35, 186.5 )
                , ( -33.7, 183.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -41.7, 148.8 )
                [ ( -38, 167.5 )
                , ( -37.7, 176.5 )
                , ( -38.3, 180.8 )
                , ( -40, 184.8 )
                , ( -43.3, 189.1 )
                , ( -44.7, 189.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -52.7, 149.8 )
                [ ( -55, 151.8 )
                , ( -62.3, 155.5 )
                , ( -67, 160.5 )
                , ( -57, 161.5 )
                , ( -49, 163.5 )
                ]
            , previewDoodleStroke previewUserId
                ( -53.3, 146.8 )
                [ ( -63, 154.5 )
                , ( -68.7, 160.1 )
                , ( -69.3, 161.8 )
                , ( -59, 164.5 )
                , ( -47.3, 165.8 )
                , ( -44.3, 166.8 )
                ]
            , previewDoodleStroke previewUserId
                ( -94, 167.1 )
                [ ( -97.3, 173.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -95, 158.1 )
                [ ( -100.3, 167.1 )
                , ( -100.7, 169.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -99, 155.8 )
                [ ( -103.3, 163.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -99.3, 151.5 )
                [ ( -105.3, 157.1 )
                ]
            , previewDoodleStroke previewUserId
                ( -109.7, 180.5 )
                [ ( -112.3, 172.5 )
                , ( -112.3, 161.8 )
                , ( -109.7, 155.5 )
                , ( -105.3, 149.5 )
                , ( -101.3, 148.1 )
                , ( -98.3, 148.1 )
                , ( -92.3, 152.1 )
                , ( -89.7, 158.8 )
                , ( -89.7, 168.5 )
                , ( -90.3, 171.1 )
                , ( -92.7, 175.8 )
                , ( -93.3, 176.1 )
                , ( -98, 175.1 )
                , ( -101, 173.5 )
                , ( -104.7, 170.1 )
                , ( -106.3, 167.5 )
                , ( -108, 159.5 )
                , ( -108, 154.1 )
                ]
            , previewDoodleStroke (Id.fromInt 3)
                ( -144.5, 39 )
                [ ( -140, 46.5 )
                , ( -138.5, 51.5 )
                , ( -129, 64 )
                , ( -125, 67 )
                , ( -116, 70.5 )
                , ( -102, 71 )
                , ( -98.5, 68.5 )
                , ( -94, 61 )
                , ( -91, 49 )
                , ( -90.5, 39 )
                , ( -89, 32 )
                , ( -89, 19 )
                , ( -88.5, 17.5 )
                ]
            , previewDoodleStroke (Id.fromInt 3)
                ( -153, 29.5 )
                [ ( -142.5, 30.5 )
                , ( -135, 29.5 )
                , ( -99.5, 15 )
                , ( -90.5, 12.5 )
                ]
            , previewDoodleStroke (Id.fromInt 3)
                ( -111, -40.5 )
                [ ( -110, -28.5 )
                , ( -108.5, -25 )
                , ( -103, -17.5 )
                , ( -103, -16.5 )
                ]
            , previewDoodleStroke (Id.fromInt 3)
                ( -152.5, -28 )
                [ ( -150.5, -18.5 )
                , ( -150.5, -14 )
                , ( -147.5, -1.5 )
                ]
            ]
        , inProgress = SeqDict.empty
        , undone = SeqDict.empty
        }
    , userIconDrawings = Drawing.emptyDrawing
    , imageAttachmentDrawings = SeqDict.empty
    , embedDrawings = SeqDict.empty
    }


previewDoodleStroke :
    Id UserId
    -> ( Float, Float )
    -> List ( Float, Float )
    -> { createdBy : Id UserId, points : Nonempty ( SafeFloat, SafeFloat ) }
previewDoodleStroke createdBy firstPoint rest =
    { createdBy = createdBy
    , points = Nonempty (previewDoodlePoint firstPoint) (List.map previewDoodlePoint rest)
    }


previewDoodlePoint : ( Float, Float ) -> ( SafeFloat, SafeFloat )
previewDoodlePoint ( x, y ) =
    ( SafeFloat.fromFloat x |> Result.withDefault SafeFloat.zero
    , SafeFloat.fromFloat y |> Result.withDefault SafeFloat.zero
    )
