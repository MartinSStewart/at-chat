module UserOptions exposing (discordBookmarkletId, domainWhitelistToString, init, view)

import Codec
import Discord
import DiscordUserData exposing (DiscordUserLoadingData(..))
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Lamdera exposing (ClientId)
import EmailAddress
import Env
import Icons
import Id exposing (AnyGuildOrDmId, ThreadRoute)
import ImageEditor
import LinkedAndOtherDiscordUsers exposing (DiscordFrontendCurrentUser)
import LocalState exposing (AdminStatus(..), LocalState)
import Log
import MyUi
import PersonName
import Ports
import Range exposing (Range)
import RichText
import Route
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import Time
import TwoFactorAuthentication
import Types exposing (FrontendMsg_(..), LoadedFrontend, LoggedIn2, UserOptionSection(..), UserOptionsModel)
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Prose
import User
import UserAgent exposing (Browser(..), Device(..), UserAgent)
import UserSession exposing (NotificationMode(..), PushSubscription(..))


init : SeqSet RichText.Domain -> UserOptionsModel
init domainWhitelist =
    { name = Editable.init
    , showLinkDiscordSetup = False
    , domainWhitelistInput = domainWhitelistToString domainWhitelist
    , serviceWorkerData = Nothing
    }


domainWhitelistToString : SeqSet RichText.Domain -> String
domainWhitelistToString domains =
    SeqSet.toList domains
        |> List.map RichText.domainToString
        |> List.sort
        |> String.join ", "


viewConnectedDevice :
    SessionIdHash
    -> Maybe (SeqDict ClientId (Maybe ( AnyGuildOrDmId, ThreadRoute )))
    -> UserAgent
    -> Element FrontendMsg_
viewConnectedDevice sessionId otherCurrentlyViewing userAgent =
    let
        browserText : String
        browserText =
            case userAgent.browser of
                Chrome ->
                    "Chrome"

                Firefox ->
                    "Firefox"

                Safari ->
                    "Safari"

                Edge ->
                    "Edge"

                Opera ->
                    "Opera"

                UnknownBrowser ->
                    "Unknown browser"

        deviceText : String
        deviceText =
            case userAgent.device of
                Desktop ->
                    "Desktop"

                Mobile ->
                    "Mobile"

                Tablet ->
                    "Tablet"
    in
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.el
            [ Ui.width (Ui.px 36)
            , Ui.height (Ui.px 36)
            ]
            (case userAgent.device of
                Desktop ->
                    Ui.html Icons.desktop

                Mobile ->
                    Ui.html Icons.mobile

                Tablet ->
                    Ui.html Icons.tablet
            )
        , Ui.column
            [ Ui.spacing 2 ]
            [ deviceText ++ " • " ++ browserText |> Ui.text
            , (case otherCurrentlyViewing of
                Just currentlyViewing ->
                    case SeqDict.size currentlyViewing of
                        1 ->
                            ""

                        0 ->
                            "Idle"

                        count ->
                            "(" ++ String.fromInt count ++ " connections)"

                Nothing ->
                    "Current device"
              )
                |> Ui.text
                |> Ui.el [ Ui.Font.color MyUi.font3, Ui.Font.size 14 ]
            ]
        , MyUi.simpleButton
            (case otherCurrentlyViewing of
                Just _ ->
                    Dom.id ("options_logout_other_" ++ SessionIdHash.toString sessionId)

                Nothing ->
                    Dom.id "options_logout"
            )
            (PressedLogOut sessionId)
            (case otherCurrentlyViewing of
                Just _ ->
                    Ui.text "Logout other"

                Nothing ->
                    Ui.row
                        [ Ui.spacing 8, Ui.paddingWith { left = 0, top = 0, bottom = 0, right = 8 }, Ui.contentCenterY ]
                        [ Ui.el [ Ui.width (Ui.px 24) ] (Ui.html Icons.logoutSvg)
                        , Ui.text "Logout"
                        ]
            )
        ]


gotoAdmin : Element FrontendMsg_
gotoAdmin =
    Ui.el
        [ Ui.paddingXY 32 0 ]
        (MyUi.simpleButton
            (Dom.id "userOptions_gotoAdmin")
            (PressedLink (Route.AdminRoute { highlightLog = Nothing }))
            (Ui.text "Go to Admin")
        )


view :
    Bool
    -> Maybe { a | htmlId : HtmlId, selection : Range }
    -> Time.Posix
    -> LocalState
    -> LoggedIn2
    -> LoadedFrontend
    -> UserOptionsModel
    -> Element FrontendMsg_
view isMobile textInputFocus time local loggedIn loaded model =
    Ui.el
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        , Ui.background MyUi.background1
        , Ui.inFront
            (Ui.row
                [ Ui.background MyUi.background1
                , MyUi.htmlStyle "padding-top" MyUi.insetTop
                , Ui.el
                    [ Ui.alignBottom
                    , Ui.paddingXY
                        (if isMobile then
                            8

                         else
                            16
                        )
                        0
                    ]
                    (Ui.el
                        [ Ui.borderWith
                            { left = 0, right = 0, top = 0, bottom = 1 }
                        , Ui.borderColor MyUi.white
                        ]
                        Ui.none
                    )
                    |> Ui.inFront
                ]
                [ Ui.el [ Ui.Font.size 20, Ui.paddingXY 16 0 ] (Ui.text "User settings")
                , MyUi.elButton
                    (Dom.id "userOptions_closeUserOptions")
                    PressedCloseUserOptions
                    [ Ui.padding 16
                    , Ui.width (Ui.px 56)
                    , Ui.alignRight
                    ]
                    (Ui.html Icons.x)
                ]
            )
        ]
        (Ui.el
            [ Ui.scrollable, Ui.heightMin 0 ]
            (Ui.column
                [ MyUi.htmlStyle
                    "padding"
                    ("calc(80px + " ++ MyUi.insetTop ++ ") 0 calc(24px + " ++ MyUi.insetBottom ++ ") 0")

                --Ui.paddingXY 0 64
                , Ui.spacing 16
                , Ui.widthMax 1000
                , Ui.centerX
                ]
                [ case local.adminData of
                    IsAdmin _ ->
                        gotoAdmin

                    IsAdminButDataNotLoaded ->
                        gotoAdmin

                    IsNotAdmin ->
                        Ui.none
                , MyUi.container
                    (SeqSet.member UserOption_Settings loggedIn.expandedUserOptions)
                    (PressedExpandContainer UserOption_Settings)
                    MyUi.background1
                    isMobile
                    "Account settings"
                    [ Editable.view
                        (Dom.id "userOptions_name")
                        False
                        "Display Name"
                        PersonName.fromString
                        UserNameEditableMsg
                        (PersonName.toString local.localUser.user.name)
                        model.name
                    , Ui.column
                        [ Ui.spacing 8 ]
                        [ Ui.el [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ] (Ui.text "Profile Picture")
                        , Ui.row
                            [ Ui.spacing 12, Ui.alignLeft ]
                            [ User.profileImage local.localUser.session.userId local.localUser.user.icon
                            , ImageEditor.view
                                loaded.windowSize
                                loggedIn.profilePictureEditor
                                |> Ui.map ProfilePictureEditorMsg
                            ]
                        ]
                    , Ui.column
                        [ Ui.spacing 8 ]
                        [ MyUi.radioColumn
                            (Dom.id "userOptions_notificationMode")
                            SelectedNotificationMode
                            (Just local.localUser.session.notificationMode)
                            (if isMobile then
                                "Notifications"

                             else
                                "Desktop notifications"
                            )
                            (if isMobile then
                                [ ( NoNotifications, "No notifications" )
                                , ( PushNotifications, "Allow notifications" )
                                ]

                             else
                                [ ( NoNotifications, "No notifications" )
                                , ( NotifyWhenRunning, "When the app is running" )
                                , ( PushNotifications, "Even when the app is closed (as long as your web browser is open)" )
                                ]
                            )
                        , case local.localUser.session.pushSubscription of
                            NotSubscribed ->
                                Ui.none

                            Subscribed _ _ ->
                                Ui.none

                            SubscriptionError subscribeData error ->
                                MyUi.errorBox
                                    (Dom.id "userOptions_pushNotificationError")
                                    PressedCopyText
                                    (Log.httpErrorToString error
                                        ++ ", Subscription: "
                                        ++ Codec.encodeToString 0 Ports.subscribeDataCodec subscribeData
                                    )

                            SubscriptionJsException jsError _ ->
                                MyUi.errorBox
                                    (Dom.id "userOptions_pushNotificationError")
                                    PressedCopyText
                                    ("JS Exception: " ++ jsError)
                        ]
                    , MyUi.radioColumn
                        (Dom.id "userOptions_emailNotifications")
                        SelectedEmailNotifications
                        (Just local.localUser.user.emailNotifications)
                        "Email notifications"
                        [ ( User.NeverNotifyMe, "No email notifications" )
                        , ( User.NotifyMeWhenMentioned, "Send me email notifications" )
                        ]

                    --, Ui.el
                    --    [ Ui.linkNewTab
                    --        (Slack.buildOAuthUrl
                    --            { clientId = Env.slackClientId
                    --            , redirectUri = Slack.redirectUri
                    --            , botScopes =
                    --                Nonempty
                    --                    "channels:read"
                    --                    [ "channels:history"
                    --                    , "users:read"
                    --                    , "team:read"
                    --                    ]
                    --            , userScopes =
                    --                Nonempty
                    --                    "channels:read"
                    --                    [ "channels:history"
                    --                    , "channels:write"
                    --                    , "groups:read"
                    --                    , "groups:history"
                    --                    , "groups:write"
                    --                    , "mpim:read"
                    --                    , "mpim:history"
                    --                    , "mpim:write"
                    --                    , "im:read"
                    --                    , "im:history"
                    --                    , "im:write"
                    --                    ]
                    --            , state = SessionIdHash.toString local.localUser.session.sessionIdHash
                    --            }
                    --        )
                    --    ]
                    --    (Ui.text "Link Slack account")
                    ]
                , MyUi.container
                    (SeqSet.member UserOption_TwoFactorAuthentication loggedIn.expandedUserOptions)
                    (PressedExpandContainer UserOption_TwoFactorAuthentication)
                    MyUi.background1
                    isMobile
                    "Two-factor authentication"
                    [ TwoFactorAuthentication.view
                        loaded.windowSize
                        textInputFocus
                        local.localUser.timezone
                        time
                        loggedIn.twoFactor
                        |> Ui.map TwoFactorMsg
                    ]
                , if SeqSet.isEmpty local.localUser.user.domainWhitelist then
                    Ui.none

                  else
                    let
                        hasChanges : Bool
                        hasChanges =
                            model.domainWhitelistInput /= domainWhitelistToString local.localUser.user.domainWhitelist
                    in
                    MyUi.container
                        (SeqSet.member UserOption_WhitelistedDomains loggedIn.expandedUserOptions)
                        (PressedExpandContainer UserOption_WhitelistedDomains)
                        MyUi.background1
                        isMobile
                        ("Whitelisted domains (" ++ String.fromInt (SeqSet.size local.localUser.user.domainWhitelist) ++ ")")
                        [ Ui.Input.multiline
                            [ MyUi.id (Dom.id "userOptions_whitelistDomains")
                            , Ui.paddingXY 8 6
                            , Ui.background MyUi.inputBackground
                            , Ui.border 1
                            , Ui.borderColor MyUi.inputBorder
                            , Ui.rounded 4
                            ]
                            { onChange = TypedDomainWhitelist
                            , text = model.domainWhitelistInput
                            , placeholder = Nothing
                            , label = Ui.Input.labelHidden "Whitelisted domains"
                            , spellcheck = False
                            }
                        , Ui.row
                            [ Ui.spacing 8, Ui.width Ui.shrink ]
                            [ if hasChanges then
                                MyUi.simpleButton
                                    (Dom.id "userOptions_saveWhitelistDomains")
                                    PressedSaveDomainWhitelist
                                    (Ui.text "Save")

                              else
                                Ui.none
                            , if hasChanges then
                                MyUi.simpleButton
                                    (Dom.id "userOptions_resetWhitelistDomains")
                                    PressedResetDomainWhitelist
                                    (Ui.text "Reset")

                              else
                                Ui.none
                            ]
                        ]
                , MyUi.container
                    (SeqSet.member UserOption_Discord loggedIn.expandedUserOptions)
                    (PressedExpandContainer UserOption_Discord)
                    MyUi.background1
                    isMobile
                    "Discord integration"
                    [ if SeqDict.isEmpty (LinkedAndOtherDiscordUsers.linkedUsers local.localUser.discordUsers) then
                        Ui.none

                      else
                        Ui.column
                            [ Ui.spacing 8 ]
                            [ Ui.el [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ] (Ui.text "Linked Discord users")
                            , Ui.column
                                [ Ui.spacing 8 ]
                                (List.map
                                    (\( discordUserId, data ) -> discordUserCard loaded discordUserId data)
                                    (SeqDict.toList (LinkedAndOtherDiscordUsers.linkedUsers local.localUser.discordUsers))
                                )
                            ]
                    , if model.showLinkDiscordSetup then
                        let
                            bookmarkletLabel =
                                Ui.Input.label
                                    (Dom.idToString discordBookmarkletId)
                                    [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ]
                                    (Ui.text "Bookmarklet URL")
                        in
                        Ui.column
                            [ Ui.spacing 16 ]
                            [ discordAcknowledgement local.localUser.user.linkDiscordAcknowledgementIsChecked
                            , if local.localUser.user.linkDiscordAcknowledgementIsChecked then
                                Ui.column
                                    [ Ui.spacing 16 ]
                                    [ Ui.el [ Ui.height (Ui.px 2), Ui.background MyUi.border1 ] Ui.none
                                    , Ui.column
                                        [ Ui.spacing 4 ]
                                        [ Ui.el [ Ui.Font.bold, Ui.Font.color MyUi.font3 ] (Ui.text "To link your Discord account:\n")
                                        , Ui.text "1. Copy the bookmarklet URL below\n"
                                        , Ui.text "2. Create a new bookmark in your browser\n"
                                        , Ui.text "3. Paste the URL as the bookmark address\n"
                                        , Ui.Prose.paragraph
                                            [ Ui.paddingXY 0 5 ]
                                            [ Ui.text "4. Go to "
                                            , Ui.el
                                                [ Ui.Font.color MyUi.textLinkColorOnDarkBackground
                                                , Ui.Font.underline
                                                , Ui.linkNewTab "https://discord.com/app"
                                                ]
                                                (Ui.text "discord.com/app")
                                            , Ui.text " in your browser and click the bookmark"
                                            ]
                                        ]
                                    , Ui.column
                                        [ Ui.spacing 2, Ui.widthMax 400 ]
                                        [ bookmarkletLabel.element
                                        , MyUi.copyBox
                                            (Dom.id "userOptions_bookmarklet")
                                            PressedCopyText
                                            TypedDiscordLinkBookmarklet
                                            loaded
                                            bookmarklet
                                        ]
                                    ]

                              else
                                Ui.none
                            ]

                      else
                        MyUi.elButton
                            (Dom.id "userOptions_linkDiscord")
                            PressedLinkDiscordUser
                            [ Ui.borderColor MyUi.buttonBorder
                            , Ui.border 1
                            , Ui.background MyUi.buttonBackground
                            , Ui.Font.color MyUi.font1
                            , Ui.width Ui.shrink
                            , Ui.paddingXY 16 8
                            , Ui.rounded 4
                            ]
                            (Ui.text "Link Discord account")
                    ]
                , MyUi.container
                    (SeqSet.member UserOption_ConnectedDevices loggedIn.expandedUserOptions)
                    (PressedExpandContainer UserOption_ConnectedDevices)
                    MyUi.background1
                    isMobile
                    "Connected devices"
                    (viewConnectedDevice local.localUser.session.sessionIdHash Nothing local.localUser.session.userAgent
                        :: List.map
                            (\( otherSessionId, otherSession ) ->
                                viewConnectedDevice otherSessionId (Just otherSession.currentlyViewing) otherSession.userAgent
                            )
                            (SeqDict.toList local.otherSessions)
                    )
                , Ui.row
                    [ Ui.paddingXY 16 0 ]
                    [ case loaded.versionNumber of
                        Just version ->
                            Ui.el
                                [ Ui.Font.size 12
                                , Ui.Font.color MyUi.font3
                                , Ui.alignRight
                                , Ui.centerY
                                ]
                                (Ui.text ("Version " ++ String.fromInt version))

                        Nothing ->
                            Ui.none
                    ]
                , MyUi.container
                    (SeqSet.member UserOption_Debug loggedIn.expandedUserOptions)
                    (PressedExpandContainer UserOption_Debug)
                    MyUi.background1
                    isMobile
                    "Debug"
                    [ Ui.column
                        [ if isMobile then
                            Ui.width Ui.fill

                          else
                            Ui.width Ui.shrink
                        ]
                        [ Ui.el
                            [ Ui.Font.size 14, Ui.Font.bold ]
                            (Ui.text "SessionId hash")
                        , MyUi.copyBox
                            (Dom.id "userOptions_sessionIdHash")
                            PressedCopyText
                            FrontendNoOp
                            loaded
                            (SessionIdHash.toString local.localUser.session.sessionIdHash)
                        ]
                    , MyUi.secondaryButton
                        (Dom.id "userOptions_unregisterServiceWorkers")
                        PressedUnregisterServiceWorkers
                        "Unregister service workers"
                    , MyUi.secondaryButton
                        (Dom.id "userOptions_loadServiceWorkerData")
                        PressedLoadServiceWorkerData
                        "Load service worker data"
                    , case model.serviceWorkerData of
                        Just serviceWorkerData ->
                            Ui.column
                                [ if isMobile then
                                    Ui.width Ui.fill

                                  else
                                    Ui.width Ui.shrink
                                ]
                                [ Ui.el
                                    [ Ui.Font.size 14, Ui.Font.bold ]
                                    (Ui.text
                                        ("Service worker data (loaded at "
                                            ++ MyUi.timestamp serviceWorkerData.loadedAt loaded.timezone
                                            ++ ")"
                                        )
                                    )
                                , MyUi.copyBox
                                    (Dom.id "userOptions_serviceWorkerData")
                                    PressedCopyText
                                    FrontendNoOp
                                    loaded
                                    serviceWorkerData.data
                                ]

                        Nothing ->
                            Ui.none
                    ]
                ]
            )
        )


discordAcknowledgement : Bool -> Element FrontendMsg_
discordAcknowledgement discordAcknowledged =
    let
        acknowledgmentLabel =
            Ui.Input.label
                "userOptions_discordAcknowledgment"
                [ Ui.pointer, Ui.width Ui.shrink ]
                (Ui.text "I have read the above and accept the risks")
    in
    Ui.column
        [ Ui.spacing 16
        , Ui.attrIf discordAcknowledged (Ui.opacity 0.5)
        ]
        [ Ui.column
            [ Ui.spacing 8 ]
            [ Ui.row
                [ Ui.spacing 8, Ui.Font.bold, Ui.Font.color MyUi.font3 ]
                [ Ui.html (Icons.warning 24), Ui.text "Before you link your Discord account, please note:" ]
            , numberPoint
                1
                (Ui.text "Using your Discord account via a 3rd party client breaks their terms of service. Discord can temporarily lock or even permanently ban your account for it. In practice this doesn't seem to happen as long as you don't act like a spam bot but the risk is still present.")
            , numberPoint
                2
                (Ui.text "Discord doesn't have any permission system for 3rd party clients. This means that if you link your Discord account with this app, you are giving us complete access to your data and to act on your behalf. You are trusting us to not abuse that level of access or accidentally let hackers access your account.")
            ]
        , Ui.row
            [ Ui.spacing 16 ]
            [ Ui.Input.checkbox
                [ Ui.Font.size 14 ]
                { onChange = PressedDiscordAcknowledgment
                , icon = Nothing
                , checked = discordAcknowledged
                , label = acknowledgmentLabel.id
                }
            , acknowledgmentLabel.element
            ]
        ]


numberPoint : Int -> Element msg -> Element msg
numberPoint index content =
    Ui.row
        [ Ui.contentTop ]
        [ Ui.el [ MyUi.noShrinking, Ui.width (Ui.px 24) ] (Ui.text (String.fromInt index ++ "."))
        , content
        ]


discordUserCard : LoadedFrontend -> Discord.Id Discord.UserId -> DiscordFrontendCurrentUser -> Element FrontendMsg_
discordUserCard loaded discordUserId data =
    Ui.column
        [ Ui.spacing 8
        , Ui.padding 12
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.rounded 8
        , Ui.widthMax 400
        ]
        [ Ui.row
            [ Ui.spacing 8 ]
            [ User.discordProfileImage discordUserId data.icon
            , Ui.column
                [ Ui.spacing 2 ]
                [ Ui.text (PersonName.toString data.name)
                , case data.email of
                    Just email ->
                        Ui.el
                            [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ]
                            (Ui.text (EmailAddress.toString email))

                    Nothing ->
                        Ui.none
                ]
            ]
        , Ui.el
            [ Ui.Font.size 13, Ui.Font.color MyUi.font3 ]
            (Ui.text ("Linked " ++ Log.timeToString loaded.timezone True data.linkedAt))
        , if data.needsAuthAgain then
            Ui.el
                [ Ui.Font.color MyUi.errorColor, Ui.Font.size 14 ]
                (Ui.text "This account needs to be linked again before you can use it")

          else
            Ui.none
        , Ui.row
            [ Ui.spacing 8 ]
            [ if data.needsAuthAgain then
                Ui.none

              else
                MyUi.elButton
                    (Dom.id ("userOptions_relinkDiscord_" ++ PersonName.toString data.name))
                    (case data.isLoadingData of
                        DiscordUserLoadingData _ ->
                            FrontendNoOp

                        _ ->
                            PressedReloadDiscordUser discordUserId
                    )
                    [ Ui.background MyUi.buttonBackground
                    , Ui.Font.color MyUi.font1
                    , Ui.width Ui.shrink
                    , Ui.paddingXY 12 0
                    , Ui.rounded 4
                    , Ui.Font.size 14
                    , Ui.contentCenterY
                    , Ui.height (Ui.px 30)
                    ]
                    (case data.isLoadingData of
                        DiscordUserLoadingData _ ->
                            Ui.row [ Ui.spacing 8, Ui.contentCenterY ] [ Ui.text "Loading user data", Icons.spinner ]

                        _ ->
                            Ui.text "Reload user data"
                    )
            , MyUi.elButton
                (Dom.id ("userOptions_unlinkDiscord_" ++ PersonName.toString data.name))
                (PressedUnlinkDiscordUser discordUserId)
                [ Ui.background MyUi.deleteButtonBackground
                , Ui.Font.color MyUi.deleteButtonFont
                , Ui.width Ui.shrink
                , Ui.paddingXY 12 0
                , Ui.rounded 4
                , Ui.Font.size 14
                , Ui.contentCenterY
                , Ui.height (Ui.px 30)
                ]
                (Ui.text "Unlink user")
            ]
        , case data.isLoadingData of
            DiscordUserLoadingFailed _ ->
                MyUi.errorBox (Dom.id "userOptions_failedToLoadDiscordUserData") PressedCopyText "Failed to load user data"

            DiscordUserLoadedSuccessfully ->
                Ui.none

            DiscordUserLoadingData _ ->
                Ui.none
        ]


discordBookmarkletId : HtmlId
discordBookmarkletId =
    Dom.id "userOptions_discordLinkBookmarklet"


bookmarklet : String
bookmarklet =
    """javascript:(function()
{
    location.reload();
    var i = document.createElement('iframe');
    document.body.appendChild(i);
    stop();
    const data = JSON.stringify(
        { token: i.contentWindow.localStorage.token.replaceAll("\\"", "")
        , userAgent: window.navigator.userAgent
        , xSuperProperties: "eyJvcyI6IkxpbnV4IiwiYnJvd3NlciI6IkZpcmVmb3giLCJkZXZpY2UiOiIiLCJzeXN0ZW1fbG9jYWxlIjoiZW4tVVMiLCJoYXNfY2xpZW50X21vZHMiOmZhbHNlLCJicm93c2VyX3VzZXJfYWdlbnQiOiJNb3ppbGxhLzUuMCAoWDExOyBVYnVudHU7IExpbnV4IHg4Nl82NDsgcnY6MTQzLjApIEdlY2tvLzIwMTAwMTAxIEZpcmVmb3gvMTQzLjAiLCJicm93c2VyX3ZlcnNpb24iOiIxNDMuMCIsIm9zX3ZlcnNpb24iOiIiLCJyZWZlcnJlciI6Imh0dHBzOi8vd3d3Lmdvb2dsZS5jb20vIiwicmVmZXJyaW5nX2RvbWFpbiI6Ind3dy5nb29nbGUuY29tIiwic2VhcmNoX2VuZ2luZSI6Imdvb2dsZSIsInJlZmVycmVyX2N1cnJlbnQiOiIiLCJyZWZlcnJpbmdfZG9tYWluX2N1cnJlbnQiOiIiLCJyZWxlYXNlX2NoYW5uZWwiOiJzdGFibGUiLCJjbGllbnRfYnVpbGRfbnVtYmVyIjo0NTMyNDgsImNsaWVudF9ldmVudF9zb3VyY2UiOm51bGwsImNsaWVudF9sYXVuY2hfaWQiOiI4NzBkNjM4MC0wZDViLTQwNjYtYmI3Zi0zNThkYjRiYmI2NzgiLCJsYXVuY2hfc2lnbmF0dXJlIjoiOGY1MTYzNjItNTBlMS00NmNmLThiMjQtMmNiZDI4M2IwMjQ3IiwiY2xpZW50X2hlYXJ0YmVhdF9zZXNzaW9uX2lkIjoiNGYwNzU4YmItNjNjZS00Njk2LWFiNDUtYTA0NmNlZGIzNTk5IiwiY2xpZW50X2FwcF9zdGF0ZSI6InVuZm9jdXNlZCJ9"
        });
    
    window.location.href = \""""
        ++ Env.domain
        ++ "/"
        ++ Route.linkDiscordPath
        ++ "/?"
        ++ Route.linkDiscordQueryParam
        ++ """=" + encodeURIComponent(data);

})()"""
        |> String.replace "\n" " "
        |> String.replace "  " " "
        |> String.replace "  " " "
        |> String.replace "  " " "
