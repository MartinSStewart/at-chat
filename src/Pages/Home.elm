module Pages.Home exposing
    ( header
    , loginButtonId
    , loginSignupText
    , view
    )

import Effect.Browser.Dom as Dom exposing (HtmlId)
import FrontendExtra
import Id
import Local
import MyUi
import Pages.Guild
import Route exposing (Route(..))
import Types exposing (FrontendMsg_(..), LoadedFrontend, LoginStatus(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Input
import Ui.Shadow


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


view : Int -> LoadedFrontend -> Element FrontendMsg_
view windowWidth loaded =
    let
        fakeLoggedIn : Types.LoggedIn2
        fakeLoggedIn =
            FrontendExtra.loadedInitHelper
                loaded.startupData
                loaded.emojiData
                { session = UserSession
                , currentlyViewing = UserSession.Viewing
                , adminData = AdminStatusLoginData
                , twoFactorAuthenticationEnabled = Maybe Time.Posix
                , guilds = SeqDict (Id GuildId) FrontendGuild
                , dmChannels = SeqDict (Id UserId) FrontendDmChannel
                , discordDmChannels = SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
                , discordGuilds = SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
                , user = FrontendCurrentUser
                , otherUsers = SeqDict (Id UserId) FrontendUser
                , discordUsers = LinkedAndOtherDiscordUsers
                , otherSessions = SeqDict SessionIdHash FrontendUserSession
                , publicVapidKey = String
                , textEditor = TextEditor.LocalState
                , stickers = SeqDict (Id StickerId) StickerData
                , customEmojis = SeqDict (Id CustomEmojiId) CustomEmojiData
                , voiceChatPeers = SeqDict CallId (NonemptyDict ( Id UserId, ClientId ) Call.RemoteCallData)
                }
                loaded
                |> Tuple.first
    in
    Ui.column
        [ MyUi.notoSans
        , if windowWidth < 800 then
            Ui.paddingWith { left = 24, right = 24, top = 120, bottom = 48 }

          else
            Ui.paddingWith { left = 48, right = 48, top = 120, bottom = 48 }
        , Ui.widthMax 1280
        , Ui.centerX
        ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text "at-chat, a place to chat with friends")
        , Pages.Guild.guildView
            loaded
            (Id.fromInt 0)
            (Route.ChannelRoute (Id.fromInt 0) (Route.NoThreadWithFriends Nothing Route.HideChannelSettings) Nothing)
            fakeLoggedIn
            (Local.model fakeLoggedIn.localState)
        ]
