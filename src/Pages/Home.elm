module Pages.Home exposing
    ( header
    , loginButtonId
    , loginSignupText
    , view
    )

import Array
import ChannelDescription
import ChannelName exposing (ChannelName)
import Coord
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Time as Time
import Emoji
import FileName
import FileStatus exposing (IsEncrypted(..))
import FrontendExtra
import GuildName exposing (GuildName)
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, GuildId, GuildOrDmId(..), Id, UserId)
import IdArray
import LinkedAndOtherDiscordUsers exposing (LinkedAndOtherDiscordUsers(..))
import Local
import LocalState exposing (FrontendChannel, FrontendGuild)
import MembersAndOwner
import Message exposing (Message(..), RepliedTo(..))
import MessageArray exposing (MessageArray)
import MyUi
import NonemptySet
import Pages.Guild
import RichText
import Route exposing (ChannelSidebarMode(..), Route(..))
import SeqDict
import SeqSet
import SessionIdHash
import String.Nonempty exposing (NonemptyString(..))
import TextEditor
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
import UserSession exposing (Viewing(..))
import VisibleMessages


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


previewChannelId : Id ChannelId
previewChannelId =
    Id.fromInt 0


previewGuildName : GuildName
previewGuildName =
    Unsafe.guildName "Friends & chat"


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
          , { name = Unsafe.personName "boog'les_the_spy_pig"
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


previewMessage : Time.Posix -> Id UserId -> NonemptyString -> Message ChannelMessageId (Id UserId)
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


previewChannel : Time.Posix -> FrontendChannel
previewChannel time =
    let
        messages : MessageArray ChannelMessageId (Id UserId)
        messages =
            List.foldl
                MessageArray.push
                MessageArray.empty
                [ UserTextMessage
                    { createdAt = time
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
                , previewMessage time previewUserId (NonemptyString 'b' "ird!")
                , previewMessage time (Id.fromInt 2) (NonemptyString 'O' "nce upon a midnight dreary while I pondered weak and weary")
                , previewMessage time previewUserId (NonemptyString '*' "NO!*")
                , previewMessage time (Id.fromInt 2) (NonemptyString 'O' "ver many a quaint and curious volume of forgotten lore")
                , previewMessage time (Id.fromInt 2) (NonemptyString 'W' "hile I nodded, nearly napping, suddenly there came a tapping")
                , previewMessage time (Id.fromInt 3) (NonemptyString 't' "hat's not a raven!!")
                ]
    in
    { createdAt = time
    , createdBy = Id.fromInt 1
    , name = previewChannelName
    , description = ChannelDescription.empty
    , messages = messages
    , visibleMessages = VisibleMessages.init True (MessageArray.length messages)
    , isArchived = Nothing
    , lastTypedAt = SeqDict.fromList [ ( Id.fromInt 2, { time = time, messageIndex = Nothing } ) ]
    , threads = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , games = SeqDict.empty
    }


previewGuild : Time.Posix -> FrontendGuild
previewGuild time =
    { createdAt = time
    , createdBy = Id.fromInt 1
    , name = previewGuildName
    , icon = Nothing
    , channels =
        SeqDict.fromList
            [ ( previewChannelId, previewChannel time )
            , ( Id.fromInt 1
              , { createdAt = time
                , createdBy = Id.fromInt 1
                , name = petPicsChannelName
                , description = ChannelDescription.empty
                , messages = MessageArray.empty
                , visibleMessages = VisibleMessages.init True 0
                , isArchived = Nothing
                , lastTypedAt = SeqDict.fromList [ ( Id.fromInt 2, { time = time, messageIndex = Nothing } ) ]
                , threads = SeqDict.empty
                , dateDividerDrawings = SeqDict.empty
                , games = SeqDict.empty
                }
              )
            ]
    , membersAndOwner =
        MembersAndOwner.init
            (SeqDict.map (\_ _ -> { joinedAt = time }) previewOtherUsers
                |> SeqDict.insert previewUserId { joinedAt = time }
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
        , signedInAt = time
        , lastClientDisconnect = Nothing
        , expandedUserOptions = SeqSet.empty
        , savedSheepGameQuestions = IdArray.empty
        }
    , currentlyViewing = Viewing_None
    , adminData = IsNotAdminLoginData
    , twoFactorAuthenticationEnabled = Nothing
    , guilds = SeqDict.fromList [ ( previewGuildId, previewGuild time ) ]
    , dmChannels = SeqDict.empty
    , discordDmChannels = SeqDict.empty
    , discordGuilds = SeqDict.empty
    , user = previewUser
    , otherUsers = previewOtherUsers
    , discordUsers = LinkedAndOtherDiscordUsers SeqDict.empty SeqDict.empty
    , otherSessions = SeqDict.empty
    , publicVapidKey = ""
    , textEditor = TextEditor.initLocalState
    , stickers = SeqDict.empty
    , customEmojis = SeqDict.empty
    , voiceChatPeers = SeqDict.empty
    }


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

        widthMax =
            1280

        paddingX =
            if Coord.xRaw loaded.windowSize < 800 then
                24

            else
                48

        previewWidth =
            min (Coord.xRaw loaded.windowSize) widthMax - paddingX * 2
    in
    Ui.column
        [ MyUi.notoSans
        , Ui.paddingWith { left = paddingX, right = paddingX, top = 120, bottom = 48 }
        , Ui.widthMax widthMax
        , Ui.centerX
        , Ui.spacing 32
        ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text "at-chat, a place to chat with friends")
        , Pages.Guild.guildView
            { loaded
                | windowSize =
                    Coord.xy
                        previewWidth
                        600
            }
            previewGuildId
            (Route.ChannelRoute previewChannelId (Route.NoThreadWithFriends Nothing Route.HideChannelSettings) Nothing)
            { previewLoggedIn | sidebarMode = ChannelSidebarNotDragging { offset = 1 } }
            (Local.model previewLoggedIn.localState)
            |> Ui.el
                ([ Ui.Shadow.shadows [ { x = 0, y = 0, blur = 10, size = 0, color = Ui.rgba 255 255 255 0.5 } ]
                 , MyUi.noPointerEvents
                 ]
                    ++ (if MyUi.isMobile loaded then
                            [ Ui.move { x = -30, y = -100, z = 0 }
                            , Ui.scale 0.8
                            , Ui.width (Ui.px (floor (toFloat previewWidth * (1 / 0.8))))
                            , Ui.height (Ui.px 600)
                            ]

                        else
                            [ Ui.scale 1, Ui.height (Ui.px 900) ]
                       )
                )
        ]
