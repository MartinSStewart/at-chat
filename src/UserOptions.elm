module UserOptions exposing (discordBookmarkletId, domainWhitelistToString, init, view)

import Codec
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord
import DiscordUserData exposing (DiscordUserLoadingData(..))
import DmChannel exposing (E2eeStatus(..))
import Drawing exposing (Drawing)
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Lamdera exposing (ClientId)
import EmailAddress
import Env
import Icons
import Id exposing (ChannelMessageId, Id, UserId)
import ImageEditor
import LinkedAndOtherDiscordUsers exposing (DiscordFrontendCurrentUser)
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (AdminStatus(..), LocalState)
import Log
import Message
import MyUi
import Pages.Guild exposing (IsHovered(..))
import PersonName
import Ports
import Range exposing (Range)
import RichText
import Route
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import String.Nonempty exposing (NonemptyString(..))
import Time
import TwoFactorAuthentication
import Types exposing (E2eeKeysValid(..), FrontendMsg_(..), LoadedFrontend, LoggedIn2, UserOptionsModel)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Input
import Ui.Prose
import User exposing (FrontendUser)
import UserAgent exposing (Browser(..), Device(..), UserAgent)
import UserColor exposing (UserColor)
import UserSession exposing (NotificationMode(..), PushSubscription(..), UserOptionSection(..))
import X25519


init : SeqSet RichText.Domain -> UserOptionsModel
init domainWhitelist =
    { name = Editable.init
    , domainWhitelistInput = domainWhitelistToString domainWhitelist
    , debugData = Nothing
    , color = Nothing
    , e2eeKeysValid = E2eeKeys_NotChecked
    }


domainWhitelistToString : SeqSet RichText.Domain -> String
domainWhitelistToString domains =
    SeqSet.toList domains
        |> List.map RichText.domainToString
        |> List.sort
        |> String.join ", "


viewConnectedDevice :
    Bool
    -> Time.Posix
    -> SessionIdHash
    -> Maybe { a | currentlyViewing : SeqDict ClientId UserSession.Viewing, lastActiveAt : Time.Posix }
    -> UserAgent
    -> Element FrontendMsg_
viewConnectedDevice isMobile time sessionId otherSession userAgent =
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
            UserAgent.deviceToString userAgent.device
    in
    Ui.row
        [ Ui.spacing 8
        , Ui.paddingWith
            { left = 16
            , right =
                if isMobile then
                    8

                else
                    16
            , top = 0
            , bottom = 0
            }
        ]
        [ Ui.el
            [ Ui.width (Ui.px 36)
            , Ui.height (Ui.px 36)
            ]
            (case userAgent.device of
                IPhone ->
                    Ui.html Icons.mobile

                IPad ->
                    Ui.html Icons.tablet

                AndroidPhone ->
                    Ui.html Icons.mobile

                AndroidTablet ->
                    Ui.html Icons.tablet

                Windows ->
                    Ui.html Icons.desktop

                MacOS ->
                    Ui.html Icons.desktop

                ChromeOS ->
                    Ui.html Icons.desktop

                Linux ->
                    Ui.html Icons.desktop

                Mobile ->
                    Ui.html Icons.mobile

                Tablet ->
                    Ui.html Icons.tablet

                Desktop ->
                    Ui.html Icons.desktop
            )
        , Ui.column
            [ Ui.spacing 2 ]
            [ deviceText ++ " • " ++ browserText |> Ui.text
            , (case otherSession of
                Just session ->
                    "Last active "
                        ++ MyUi.timeElapsed time session.lastActiveAt
                        ++ (case SeqDict.size session.currentlyViewing of
                                0 ->
                                    ""

                                1 ->
                                    ""

                                count ->
                                    " (" ++ String.fromInt count ++ " connections)"
                           )

                Nothing ->
                    "Current device"
              )
                |> Ui.text
                |> Ui.el [ Ui.Font.color MyUi.font3, Ui.Font.size 14 ]
            ]
        , MyUi.simpleButton
            (case otherSession of
                Just _ ->
                    Dom.id ("options_logout_other_" ++ SessionIdHash.toString sessionId)

                Nothing ->
                    Dom.id "options_logout"
            )
            (PressedLogOut sessionId)
            (case otherSession of
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
    Coord CssPixels
    -> Maybe { a | htmlId : HtmlId, selection : Range }
    -> Time.Posix
    -> LocalState
    -> LoggedIn2
    -> LoadedFrontend
    -> UserOptionsModel
    -> Element FrontendMsg_
view windowSize textInputFocus time local loggedIn loaded model =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            User.allUsers local.localUser

        isMobile =
            MyUi.isMobileAlt windowSize
    in
    Ui.el
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        , Ui.background MyUi.background1
        , Ui.inFront
            (Ui.el
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
                        [ Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
                        , Ui.borderColor MyUi.white
                        ]
                        Ui.none
                    )
                    |> Ui.inFront
                ]
                (Ui.row
                    [ Ui.Font.size 20, Ui.widthMax 1000, Ui.centerX ]
                    [ Ui.el [ Ui.paddingXY 16 0 ] (Ui.text "User settings")
                    , MyUi.rowButton
                        (Dom.id "userOptions_closeUserOptions")
                        PressedCloseUserOptions
                        [ Ui.padding 16
                        , Ui.alignRight
                        , Ui.Font.color
                            (if isMobile then
                                MyUi.font1

                             else
                                MyUi.font3
                            )
                        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                        , Ui.spacing 8
                        , MyUi.hoverText "Close"
                        ]
                        [ if isMobile then
                            Ui.none

                          else
                            Ui.el [ Ui.alignBottom ] (Ui.text "Close")
                        , Ui.html Icons.x
                        ]
                    ]
                )
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
                    16
                    (SeqSet.member UserOption_Settings local.localUser.session.expandedUserOptions)
                    (Dom.id "userOptions_settings")
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
                        |> Ui.el [ Ui.paddingXY 16 0 ]
                    , Ui.column
                        [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                        [ Ui.el [ Ui.Font.bold ] (Ui.text "Email")
                        , Ui.text (EmailAddress.toString local.localUser.user.email)
                        ]
                    , Ui.column
                        [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                        [ Ui.el [ Ui.Font.bold ] (Ui.text "Profile Picture")
                        , Ui.row
                            [ Ui.spacing 12, Ui.alignLeft ]
                            [ User.profileImage (Just local.localUser.user)
                            , ImageEditor.view
                                loaded.windowSize
                                (local.localUser.user.icon /= Nothing)
                                loggedIn.profilePictureEditor
                                |> Ui.map ProfilePictureEditorMsg
                            ]
                        ]
                    , Ui.column
                        [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                        [ MyUi.radioColumn
                            (Dom.id "userOptions_notificationMode")
                            SelectedNotificationMode
                            (Just local.localUser.session.notificationMode)
                            (if isMobile then
                                Ui.text "Notifications"

                             else
                                Ui.text "Desktop notifications"
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
                        (Ui.text "Email notifications")
                        [ ( User.NeverNotifyMe, "No email notifications" )
                        , ( User.NotifyMeWhenMentioned, "Send me email notifications" )
                        ]
                        |> Ui.el [ Ui.paddingXY 16 0 ]
                    , Ui.column
                        [ Ui.spacing 8 ]
                        (Ui.el [ Ui.Font.bold, Ui.paddingXY 16 0 ] (Ui.text "Color")
                            :: Ui.el
                                [ Ui.paddingXY 16 0 ]
                                (Ui.text "This is the color used for your drawings or to represent you in some games.")
                            :: (case model.color of
                                    Nothing ->
                                        [ Ui.row
                                            [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                                            [ currentColorSquare local.localUser.user.color
                                            , MyUi.secondaryButtonTall
                                                (Dom.id "userOptions_selectColor")
                                                PressedSelectNewColor
                                                "Select new color"
                                            ]
                                        ]

                                    Just selection ->
                                        [ colorPreview time isMobile local allUsers (UserColor.picked selection)
                                            |> Ui.el [ Ui.paddingXY 16 0 ]
                                        , UserColor.picker isMobile (Coord.xRaw windowSize - 16 * 2) selection SelectedUserColor
                                        , Ui.row
                                            [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                                            [ if UserColor.picked selection == local.localUser.user.color then
                                                Ui.none

                                              else
                                                MyUi.simpleButton
                                                    (Dom.id "userOptions_submitColor")
                                                    PressedSubmitUserColor
                                                    (Ui.text "Submit")
                                            , MyUi.secondaryButtonTall
                                                (Dom.id "userOptions_resetColor")
                                                PressedResetUserColor
                                                "Reset"
                                            ]
                                        ]
                               )
                        )
                    ]
                , MyUi.container
                    16
                    (SeqSet.member UserOption_TwoFactorAuthentication local.localUser.session.expandedUserOptions)
                    (Dom.id "userOptions_twoFactor")
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
                        |> Ui.el [ Ui.paddingXY 16 0 ]
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
                        16
                        (SeqSet.member UserOption_WhitelistedDomains local.localUser.session.expandedUserOptions)
                        (Dom.id "userOptions_whitelistedDomains")
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
                            |> Ui.el [ Ui.paddingXY 16 0 ]
                        , if hasChanges then
                            Ui.row
                                [ Ui.spacing 8, Ui.width Ui.shrink, Ui.paddingXY 16 0 ]
                                [ MyUi.simpleButton
                                    (Dom.id "userOptions_saveWhitelistDomains")
                                    PressedSaveDomainWhitelist
                                    (Ui.text "Save")
                                , MyUi.simpleButton
                                    (Dom.id "userOptions_resetWhitelistDomains")
                                    PressedResetDomainWhitelist
                                    (Ui.text "Reset")
                                ]

                          else
                            Ui.none
                        ]
                , MyUi.container
                    16
                    (SeqSet.member UserOption_E2ee local.localUser.session.expandedUserOptions)
                    (Dom.id "userOptions_e2eeSection")
                    (PressedExpandContainer UserOption_E2ee)
                    MyUi.background1
                    isMobile
                    "End-to-end encryption"
                    (case local.localUser.user.publicKey of
                        Just publicKey ->
                            let
                                e2eeDmChannels =
                                    List.filterMap
                                        (\( otherUserId, channel ) ->
                                            case ( channel.e2ee, User.getUser otherUserId local.localUser ) of
                                                ( E2eeEnabled enabledAt, Just otherUser ) ->
                                                    Pages.Guild.friendLabel
                                                        isMobile
                                                        time
                                                        False
                                                        local.localUser
                                                        otherUserId
                                                        otherUser
                                                        channel
                                                        |> Just

                                                _ ->
                                                    Nothing
                                        )
                                        (SeqDict.toList local.dmChannels)

                                privateKeyLabel =
                                    Ui.Input.label
                                        "userOptions_privateKey"
                                        []
                                        (Ui.text "You can paste your private key here to verify your public + private key pair is valid.")
                            in
                            [ MyUi.copyBox
                                (Dom.id "userOptions_publicKey")
                                (Just "Your public key")
                                PressedCopyText
                                FrontendNoOp
                                loaded
                                (X25519.publicKeyToString publicKey)
                                |> Ui.el [ Ui.paddingXY 16 0, Ui.widthMax 400 ]
                            , Ui.column
                                []
                                [ privateKeyLabel.element
                                , Ui.Input.text
                                    []
                                    { text = ""
                                    , onChange =
                                        \text ->
                                            (case X25519.privateKeyFromString text of
                                                Ok privateKey ->
                                                    if X25519.toPublicKey privateKey == publicKey then
                                                        Ok ()

                                                    else
                                                        Err "Public + private key pairing is invalid"

                                                Err error ->
                                                    Err error
                                            )
                                                |> ValidatedE2eePrivateKey
                                    , placeholder = Nothing
                                    , label = privateKeyLabel.id
                                    }
                                , case model.e2eeKeysValid of
                                    E2eeKeys_NotChecked ->
                                        Ui.none

                                    E2eeKeys_Error error ->
                                        Ui.el [ Ui.Font.color MyUi.errorColor ] (Ui.text error)

                                    E2eeKeys_Valid ->
                                        Ui.text "Public + private key pair is valid!"
                                ]
                            , case e2eeDmChannels of
                                [] ->
                                    Ui.el [ Ui.paddingXY 16 0 ] (Ui.text "E2EE not enabled for an DM channels yet.")

                                _ ->
                                    Ui.column
                                        [ Ui.spacing 8 ]
                                        [ Ui.el [ Ui.paddingXY 16 0 ] (Ui.text "E2EE enabled for ")
                                        , Ui.column [ Ui.paddingXY 12 0, Ui.widthMax 400 ] e2eeDmChannels
                                        ]
                            ]

                        Nothing ->
                            [ Ui.Prose.paragraph
                                [ Ui.paddingXY 0 4 ]
                                [ Ui.text "You have not enabled E2EE for any direct message channels yet. Open a direct message channel and click on the "
                                , Ui.html Icons.gear
                                , Ui.text " to do so."
                                ]
                            ]
                    )
                , MyUi.container
                    16
                    (SeqSet.member UserOption_Discord local.localUser.session.expandedUserOptions)
                    (Dom.id "userOptions_discordSection")
                    (PressedExpandContainer UserOption_Discord)
                    MyUi.background1
                    isMobile
                    "Discord"
                    [ if SeqDict.isEmpty (LinkedAndOtherDiscordUsers.linkedUsers local.localUser.discordUsers) then
                        Ui.none

                      else
                        Ui.column
                            [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                            [ Ui.el [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ] (Ui.text "Linked Discord users")
                            , Ui.column
                                [ Ui.spacing 8 ]
                                (List.map
                                    (\( discordUserId, data ) -> discordUserCard loaded discordUserId data)
                                    (SeqDict.toList (LinkedAndOtherDiscordUsers.linkedUsers local.localUser.discordUsers))
                                )
                            ]
                    , Ui.column
                        [ Ui.spacing 16, Ui.paddingXY 16 0 ]
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
                                        , Ui.text " in your browser"
                                        ]
                                    , Ui.text "5. Make sure you are logged in on Discord and then click on the bookmark"
                                    ]
                                , Ui.el
                                    [ Ui.widthMax 400 ]
                                    (MyUi.copyBox
                                        (Dom.id "userOptions_bookmarklet")
                                        (Just "Bookmarklet URL")
                                        PressedCopyText
                                        TypedDiscordLinkBookmarklet
                                        loaded
                                        bookmarklet
                                    )
                                ]

                          else
                            Ui.none
                        ]
                    ]
                , MyUi.container
                    10
                    (SeqSet.member UserOption_ConnectedDevices local.localUser.session.expandedUserOptions)
                    (Dom.id "userOptions_connectedDevices")
                    (PressedExpandContainer UserOption_ConnectedDevices)
                    MyUi.background1
                    isMobile
                    "Connected devices"
                    (viewConnectedDevice
                        isMobile
                        time
                        local.localUser.session.sessionIdHash
                        Nothing
                        local.localUser.session.userAgent
                        :: List.map
                            (\( otherSessionId, otherSession ) ->
                                viewConnectedDevice isMobile time otherSessionId (Just otherSession) otherSession.userAgent
                            )
                            (SeqDict.toList local.otherSessions)
                    )
                , MyUi.container
                    16
                    (SeqSet.member UserOption_Debug local.localUser.session.expandedUserOptions)
                    (Dom.id "userOptions_debug")
                    (PressedExpandContainer UserOption_Debug)
                    MyUi.background1
                    isMobile
                    "Debug"
                    [ Ui.column
                        [ if isMobile then
                            Ui.width Ui.fill

                          else
                            Ui.width Ui.shrink
                        , Ui.paddingXY 16 0
                        ]
                        [ MyUi.copyBox
                            (Dom.id "userOptions_sessionIdHash")
                            (Just "SessionId hash")
                            PressedCopyText
                            FrontendNoOp
                            loaded
                            (SessionIdHash.toString local.localUser.session.sessionIdHash)
                        ]
                    , MyUi.secondaryButton
                        (Dom.id "userOptions_unregisterServiceWorkers")
                        PressedUnregisterServiceWorkers
                        "Unregister service workers"
                        |> Ui.el [ Ui.paddingXY 16 0 ]
                    , MyUi.secondaryButton
                        (Dom.id "userOptions_loadDebugData")
                        PressedLoadDebugData
                        "Load debug data"
                        |> Ui.el [ Ui.paddingXY 16 0 ]
                    , case model.debugData of
                        Just debugData ->
                            Ui.el
                                [ if isMobile then
                                    Ui.width Ui.fill

                                  else
                                    Ui.width Ui.shrink
                                , Ui.paddingXY 16 0
                                ]
                                (MyUi.copyBox
                                    (Dom.id "userOptions_debugData")
                                    (Just
                                        ("Debug data (loaded at "
                                            ++ MyUi.timestamp debugData.loadedAt loaded.timezone
                                            ++ ")"
                                        )
                                    )
                                    PressedCopyText
                                    FrontendNoOp
                                    loaded
                                    debugData.data
                                )

                        Nothing ->
                            Ui.none
                    , Ui.text
                        ("App version: "
                            ++ (case loaded.versionNumber of
                                    Just version ->
                                        String.fromInt version

                                    Nothing ->
                                        "unknown"
                               )
                        )
                        |> Ui.el [ Ui.paddingXY 16 0 ]
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
                [ Ui.paddingWith { left = 16, right = 0, top = 0, bottom = 0 }, Ui.pointer, Ui.width Ui.shrink ]
                (Ui.text "I have read the above and accept the risks")
    in
    Ui.column
        [ Ui.spacing 16
        , Ui.attrIf discordAcknowledged (Ui.opacity 0.5)
        ]
        [ Ui.column
            [ Ui.spacing 8 ]
            [ MyUi.warningHeader "Before you link your Discord account, please note:"
            , numberPoint
                1
                (Ui.text "Using your Discord account via a 3rd party client breaks their terms of service. Discord can temporarily or even permanently ban your account for it. In practice this doesn't seem to happen as long as you don't act like a spam bot but the risk is still present.")
            , numberPoint
                2
                (Ui.text "Discord doesn't have any permission system for 3rd party clients. This means that if you link your Discord account with this app, you are giving us complete access to your data and to act on your behalf. You are trusting us to not abuse that level of access or accidentally let hackers access your account.")
            ]
        , Ui.row
            []
            [ Ui.Input.checkbox
                []
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
                , Ui.border 1
                , Ui.borderColor MyUi.deleteButtonBorder
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


{-| The colour the user has now, next to the grid of ones they could have instead.
-}
currentColorSquare : UserColor -> Element FrontendMsg_
currentColorSquare color =
    Ui.el
        [ Ui.id (Dom.idToString (Dom.id "userOptions_currentColor"))
        , Ui.width (Ui.px 40)
        , Ui.height (Ui.px 40)
        , Ui.alignTop
        , Ui.rounded 3
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.background (UserColor.toColor color)
        ]
        Ui.none


{-| A message with the colour drawn on it the way the drawing tool would leave it, so that
the picker shows what a colour is actually going to look like rather than just a square of
it.
-}
colorPreview :
    Time.Posix
    -> Bool
    -> LocalState
    -> SeqDict (Id UserId) FrontendUser
    -> UserColor
    -> Element FrontendMsg_
colorPreview time isMobile local allUsers color =
    let
        message : Message.UserTextMessageData ChannelMessageId (Id UserId)
        message =
            Message.userTextMessageNoEmbeds
                time
                local.localUser.session.userId
                (NonemptyString '#' "# Hello" |> RichText.fromNonemptyString local.localUser.timezone allUsers)
                SeqDict.empty
                Nothing
                SeqDict.empty
    in
    Pages.Guild.userTextMessageContent
        time
        (Dom.id "userOptions_colorPreviewSpoiler")
        200
        False
        isMobile
        Nothing
        local.localUser
        SeqDict.empty
        (SeqDict.fromList
            [ ( local.localUser.session.userId
              , { color = color, name = local.localUser.user.name, icon = local.localUser.user.icon, publicKey = Nothing }
              )
            ]
        )
        (\_ -> color)
        IsNotHovered
        (Id.fromInt 0)
        message.content
        message.embeds
        { message | userIconDrawings = exampleDrawing local.localUser.session.userId }
        |> Ui.map (\_ -> FrontendNoOp)
        |> Ui.el [ Ui.background MyUi.background3, Ui.widthMax 400, Ui.paddingXY 8 4 ]


exampleDrawing : Id UserId -> Drawing (Id UserId)
exampleDrawing userId =
    { finished =
        [ Nonempty ( 205, 28.503 ) [ ( 205, 28.503 ), ( 205, 27.5 ), ( 205, 25.5 ), ( 205, 22.497 ), ( 205, 19.503 ), ( 205, 16.5 ), ( 205, 13.501 ), ( 205, 11.501 ), ( 205, 10.499 ) ]
        , Nonempty ( 204.4, 35.5 ) [ ( 204.4, 34.5 ), ( 204.4, 34.5 ), ( 204.4, 34.5 ), ( 204.4, 34.5 ), ( 204.6, 34.5 ), ( 204.6, 34.5 ), ( 204.6, 34.5 ), ( 204.6, 34.5 ), ( 204.6, 34.5 ), ( 204.6, 33.5 ), ( 204.6, 33.5 ), ( 204.6, 33.5 ), ( 204.6, 33.5 ), ( 204.6, 33.5 ), ( 204.6, 33.5 ), ( 204.6, 33.5 ), ( 204.6, 33.5 ) ]
        , Nonempty ( 184.2, 17.5 ) [ ( 184.4, 17.5 ), ( 184.6, 17.5 ), ( 185.6, 17.5 ), ( 187.2, 17.5 ), ( 189, 17.5 ), ( 190.8, 17.5 ), ( 192.2, 17.5 ), ( 193.8, 17.5 ), ( 194.6, 17.5 ), ( 195.2, 17.5 ), ( 195.4, 17.5 ), ( 195.6, 17.5 ), ( 195.6, 17.5 ) ]
        , Nonempty ( 190.4, 35.5 ) [ ( 190.4, 35.5 ), ( 190.4, 34.5 ), ( 190.4, 33.5 ), ( 190.4, 31.503 ), ( 190.4, 29.5 ), ( 190.4, 27.503 ), ( 190.4, 25.5 ), ( 190.4, 24.5 ), ( 190.4, 22.497 ), ( 190.4, 21.5 ), ( 190.4, 20.5 ), ( 190.4, 19.503 ), ( 190.4, 17.497 ), ( 190.4, 16.5 ), ( 190.4, 15.497 ), ( 190.4, 15.499 ), ( 190.4, 15.503 ), ( 190.4, 15.503 ), ( 190.4, 15.5 ), ( 190.4, 15.5 ), ( 190.4, 14.497 ), ( 190.4, 14.503 ), ( 190.4, 13.501 ), ( 190.4, 13.503 ), ( 190.4, 13.5 ), ( 190.4, 12.497 ), ( 190.4, 12.497 ) ]
        , Nonempty ( 182, 35.5 ) [ ( 182, 35.5 ), ( 182, 34.5 ), ( 182, 34.5 ), ( 182, 33.5 ), ( 182, 32.5 ), ( 182, 31.503 ), ( 182, 30.503 ), ( 181.8, 29.5 ), ( 181.6, 28.5 ), ( 181.4, 27.5 ), ( 181.2, 26.497 ), ( 180.8, 26.503 ), ( 180.6, 25.497 ), ( 180.4, 25.5 ), ( 180.2, 25.5 ), ( 180, 24.5 ), ( 180, 24.503 ), ( 179.8, 24.5 ), ( 179.4, 23.497 ), ( 179, 23.5 ), ( 178.6, 23.503 ), ( 177.8, 22.497 ), ( 177.6, 22.5 ), ( 176.8, 22.5 ), ( 176.8, 22.5 ), ( 176.6, 22.5 ), ( 176.2, 22.5 ), ( 176, 22.5 ), ( 175.8, 22.5 ), ( 175.4, 22.5 ), ( 175.2, 22.5 ), ( 175, 22.497 ), ( 174.8, 23.503 ), ( 174.8, 23.503 ), ( 174.6, 23.5 ), ( 174.6, 23.5 ), ( 174.4, 24.5 ), ( 174.2, 24.5 ), ( 174, 25.5 ), ( 173.8, 25.5 ), ( 173.6, 26.503 ), ( 173.6, 26.5 ), ( 173.6, 27.503 ), ( 173.4, 28.5 ), ( 173.4, 28.5 ), ( 173.4, 29.503 ), ( 173.4, 29.5 ), ( 173.4, 30.503 ), ( 173.4, 30.5 ), ( 173.4, 30.497 ), ( 173.4, 31.503 ), ( 173.4, 31.5 ), ( 173.4, 31.5 ), ( 173.4, 31.497 ), ( 173.4, 32.5 ), ( 173.6, 32.5 ), ( 173.6, 32.5 ), ( 173.8, 32.5 ), ( 174.2, 32.5 ), ( 174.4, 32.5 ), ( 174.8, 33.5 ), ( 175, 33.5 ), ( 175.2, 33.5 ), ( 175.4, 33.5 ), ( 175.6, 33.5 ), ( 176, 33.5 ), ( 176.4, 33.5 ), ( 176.8, 33.5 ), ( 177.2, 33.5 ), ( 177.6, 33.5 ), ( 178, 33.5 ), ( 178.2, 33.5 ), ( 178.6, 33.5 ), ( 178.8, 33.5 ), ( 179, 33.5 ), ( 179.2, 33.5 ), ( 179.4, 33.5 ), ( 179.6, 32.5 ), ( 179.8, 32.5 ), ( 180, 32.5 ), ( 180.4, 32.5 ), ( 180.4, 32.5 ), ( 180.4, 32.5 ), ( 180.6, 32.5 ), ( 180.6, 32.5 ), ( 180.8, 32.5 ), ( 180.8, 32.5 ), ( 180.8, 32.5 ), ( 181, 32.5 ), ( 181, 31.497 ) ]
        , Nonempty ( 157.8, 35.5 ) [ ( 157.8, 35.5 ), ( 157.8, 34.5 ), ( 157.8, 33.5 ), ( 157.8, 32.5 ), ( 157.6, 31.5 ), ( 157.8, 30.503 ), ( 158.2, 29.503 ), ( 158.4, 28.5 ), ( 158.8, 28.5 ), ( 159.4, 27.503 ), ( 160, 26.5 ), ( 160.4, 25.497 ), ( 160.8, 25.503 ), ( 161, 24.5 ), ( 161.4, 24.5 ), ( 161.6, 24.5 ), ( 161.8, 23.497 ), ( 162, 23.5 ), ( 162.2, 23.5 ), ( 162.4, 23.5 ), ( 162.6, 23.5 ), ( 162.8, 23.5 ), ( 163.2, 23.5 ), ( 163.6, 23.5 ), ( 163.8, 23.5 ), ( 164.2, 23.5 ), ( 164.4, 23.5 ), ( 164.6, 23.5 ), ( 164.8, 23.5 ), ( 165, 23.5 ), ( 165.2, 23.497 ), ( 165.4, 24.503 ), ( 165.8, 24.5 ), ( 166.2, 25.5 ), ( 166.4, 25.5 ), ( 166.8, 26.5 ), ( 167.2, 26.5 ), ( 167.6, 27.5 ), ( 168, 27.5 ), ( 168.2, 28.5 ), ( 168.4, 28.5 ), ( 168.8, 29.5 ), ( 168.8, 29.5 ), ( 169, 30.503 ), ( 169.2, 30.497 ), ( 169.2, 31.503 ), ( 169.4, 31.497 ), ( 169.4, 32.5 ), ( 169.4, 32.5 ), ( 169.4, 32.5 ), ( 169.4, 33.5 ), ( 169.4, 33.5 ), ( 169.4, 33.5 ), ( 169.4, 33.5 ), ( 169.4, 33.5 ), ( 169.4, 33.5 ), ( 169.4, 34.5 ), ( 169.4, 34.5 ) ]
        , Nonempty ( 157.6, 35.5 ) [ ( 157.6, 35.5 ), ( 157.6, 35.5 ), ( 157.6, 33.5 ), ( 157.6, 31.5 ), ( 157.6, 27.503 ), ( 157.6, 22.5 ), ( 157.6, 18.5 ), ( 157.6, 15.497 ), ( 157.6, 14.5 ), ( 157.6, 13.503 ), ( 157.6, 12.497 ), ( 157.6, 12.501 ), ( 157.6, 12.499 ), ( 157.6, 12.503 ), ( 157.6, 12.5 ), ( 157.6, 11.497 ), ( 157.8, 11.501 ), ( 157.8, 11.499 ), ( 157.8, 11.499 ) ]
        , Nonempty ( 151.2, 37.5 ) [ ( 151, 37.5 ), ( 150.6, 37.5 ), ( 150, 37.5 ), ( 149.2, 37.5 ), ( 148.2, 37.5 ), ( 147.4, 37.5 ), ( 146.8, 37.5 ), ( 146.4, 37.5 ), ( 145.8, 37.5 ), ( 145.4, 37.5 ), ( 144.8, 36.5 ), ( 144, 36.5 ), ( 143.4, 35.5 ), ( 142.8, 35.5 ), ( 142.4, 34.5 ), ( 142, 34.5 ), ( 141.6, 34.5 ), ( 141.4, 33.5 ), ( 141.2, 33.5 ), ( 141.2, 33.5 ), ( 141, 32.5 ), ( 141, 32.5 ), ( 141, 31.5 ), ( 141, 31.503 ), ( 141, 30.5 ), ( 141.2, 30.503 ), ( 141.4, 29.497 ), ( 141.8, 29.5 ), ( 142.6, 29.5 ), ( 143.4, 28.5 ), ( 144.2, 28.5 ), ( 145.2, 27.5 ), ( 146.6, 26.5 ), ( 147.2, 26.503 ), ( 147.6, 26.503 ), ( 148.2, 26.5 ), ( 149.4, 25.497 ), ( 150, 25.5 ), ( 150.8, 25.5 ), ( 151.2, 25.5 ), ( 151.6, 25.5 ), ( 151.8, 25.5 ), ( 152, 25.5 ) ]
        , Nonempty ( 126.6, 28.503 ) [ ( 126.6, 28.503 ), ( 126.01, 28.503 ), ( 127.99, 28.503 ), ( 127.01, 28.503 ), ( 128.8, 28.503 ), ( 129.6, 28.503 ), ( 130.2, 28.503 ), ( 131.6, 28.503 ), ( 132, 28.503 ), ( 132.4, 28.503 ), ( 132.6, 28.503 ), ( 132.6, 28.503 ) ]
        , Nonempty ( 109.6, 22.497 ) [ ( 109.8, 22.497 ), ( 111, 22.497 ), ( 112.8, 22.497 ), ( 115.2, 22.497 ), ( 117.6, 22.497 ), ( 119.2, 22.497 ), ( 120.6, 22.497 ), ( 122, 22.497 ), ( 122.01, 22.497 ), ( 123.4, 22.497 ), ( 123.01, 22.497 ), ( 123.01, 22.497 ), ( 124, 22.497 ), ( 124.99, 22.497 ) ]
        , Nonempty ( 117.4, 17.503 ) [ ( 117.4, 17.5 ), ( 117.4, 18.5 ), ( 117.4, 20.5 ), ( 117.4, 21.5 ), ( 117.4, 22.497 ), ( 117.4, 25.5 ), ( 117.4, 26.5 ), ( 117.4, 27.503 ), ( 117.4, 28.5 ), ( 117.4, 30.5 ), ( 117.4, 31.5 ), ( 117.4, 32.5 ), ( 117.6, 34.5 ), ( 117.6, 35.5 ), ( 117.8, 36.5 ), ( 118, 36.5 ), ( 118, 37.5 ), ( 118, 37.5 ), ( 118.2, 37.5 ), ( 118.2, 37.5 ), ( 118.2, 37.5 ) ]
        , Nonempty ( 111, 37.5 ) [ ( 111, 37.5 ), ( 111, 37.5 ), ( 111, 36.5 ), ( 111, 35.5 ), ( 110.6, 35.5 ), ( 110, 34.5 ), ( 109.4, 33.5 ), ( 108.8, 32.5 ), ( 108.2, 31.503 ), ( 107.6, 30.5 ), ( 107.2, 30.5 ), ( 107, 29.5 ), ( 106.6, 29.5 ), ( 106.4, 28.5 ), ( 106.2, 28.5 ), ( 105.8, 27.5 ), ( 105.4, 27.503 ), ( 105, 26.5 ), ( 104.6, 26.5 ), ( 104, 25.5 ), ( 103.6, 25.503 ), ( 103.2, 25.5 ), ( 102.6, 24.497 ), ( 102.2, 24.5 ), ( 101.6, 24.5 ), ( 101.2, 24.5 ), ( 100.8, 24.5 ), ( 100.4, 24.5 ), ( 100.2, 24.5 ), ( 100, 24.5 ), ( 99.4, 24.497 ), ( 99, 25.5 ), ( 98.8, 25.5 ), ( 98.4, 26.5 ), ( 98.4, 26.5 ), ( 98.2, 27.503 ), ( 98, 27.497 ), ( 98, 28.5 ), ( 97.8, 29.5 ), ( 97.8, 30.503 ), ( 97.8, 31.5 ), ( 97.8, 31.497 ), ( 97.8, 32.5 ), ( 97.8, 33.5 ), ( 97.8, 33.5 ), ( 98, 34.5 ), ( 98, 34.5 ), ( 98, 34.5 ), ( 98.2, 35.5 ), ( 98.4, 35.5 ), ( 98.6, 36.5 ), ( 98.8, 36.5 ), ( 99, 36.5 ), ( 99.2, 37.5 ), ( 99.6, 37.5 ), ( 99.8, 37.5 ), ( 100.2, 37.5 ), ( 100.6, 37.5 ), ( 101.2, 37.5 ), ( 101.8, 37.5 ), ( 102.2, 37.5 ), ( 102.8, 37.5 ), ( 103.2, 37.5 ), ( 103.8, 37.5 ), ( 104.2, 36.5 ), ( 104.8, 36.5 ), ( 105.4, 36.5 ), ( 106, 35.5 ), ( 106.4, 35.5 ), ( 106.8, 35.5 ), ( 107.2, 34.5 ), ( 107.4, 34.5 ), ( 107.6, 34.5 ), ( 107.8, 34.5 ), ( 108, 34.5 ), ( 108, 33.5 ), ( 108.2, 33.5 ), ( 108.4, 33.5 ), ( 108.4, 33.5 ), ( 108.6, 33.5 ), ( 108.6, 33.5 ), ( 108.6, 33.5 ), ( 108.6, 33.5 ), ( 108.6, 33.5 ), ( 108.6, 33.5 ), ( 108.6, 33.5 ) ]
        ]
            |> List.map (\points -> { createdBy = userId, points = List.Nonempty.map (\( x, y ) -> ( x + 20, y + 10 )) points })
    , inProgress = SeqDict.empty
    , undone = SeqDict.empty
    }
