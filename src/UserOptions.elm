module UserOptions exposing (init, view)

import Editable
import Effect.Browser.Dom as Dom
import Effect.Lamdera as Lamdera
import Env
import Html
import Html.Attributes
import Icons
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (AdminStatus(..), DiscordBotToken(..), LocalState, NotificationMode(..), PrivateVapidKey(..), PushSubscription(..))
import Log
import MyUi
import PersonName
import Slack
import Time
import TwoFactorAuthentication
import Types exposing (FrontendMsg(..), LoggedIn2, UserOptionsModel)
import Ui exposing (Element)
import Ui.Font
import UserAgent exposing (Browser(..), Device(..), UserAgent)


init : UserOptionsModel
init =
    { name = Editable.init
    , botToken = Editable.init
    , slackClientSecret = Editable.init
    , publicVapidKey = Editable.init
    , privateVapidKey = Editable.init
    }


view : UserAgent -> Bool -> Time.Posix -> LocalState -> LoggedIn2 -> UserOptionsModel -> Element FrontendMsg
view userAgent isMobile time local loggedIn model =
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
        (Ui.column
            [ MyUi.htmlStyle
                "padding"
                ("calc(80px + " ++ MyUi.insetTop ++ ") 0 calc(24px + " ++ MyUi.insetBottom ++ ") 0")

            --Ui.paddingXY 0 64
            , Ui.spacing 16
            , Ui.scrollable
            ]
            [ case local.adminData of
                IsAdmin adminData2 ->
                    MyUi.container
                        isMobile
                        "Admin"
                        [ Editable.view
                            (Dom.id "userOptions_botToken")
                            True
                            "Discord bot token"
                            (\text ->
                                let
                                    text2 =
                                        String.trim text
                                in
                                if text2 == "" then
                                    Ok Nothing

                                else
                                    Just (DiscordBotToken text2) |> Ok
                            )
                            BotTokenEditableMsg
                            (case adminData2.botToken of
                                Just (DiscordBotToken a) ->
                                    a

                                Nothing ->
                                    ""
                            )
                            model.botToken
                        , Editable.view
                            (Dom.id "userOptions_slackClientSecret")
                            True
                            "Slack client secret"
                            (\text ->
                                let
                                    text2 =
                                        String.trim text
                                in
                                if text2 == "" then
                                    Ok Nothing

                                else
                                    Just (Slack.ClientSecret text2) |> Ok
                            )
                            SlackClientSecretEditableMsg
                            (case adminData2.slackClientSecret of
                                Just (Slack.ClientSecret a) ->
                                    a

                                Nothing ->
                                    ""
                            )
                            model.slackClientSecret
                        , Editable.view
                            (Dom.id "userOptions_publicVapidKey")
                            True
                            "Public VAPID key"
                            (\text -> String.trim text |> Ok)
                            PublicVapidKeyEditableMsg
                            local.publicVapidKey
                            model.publicVapidKey
                        , Editable.view
                            (Dom.id "userOptions_privateVapidKey")
                            True
                            "Private VAPID key"
                            (\text -> String.trim text |> PrivateVapidKey |> Ok)
                            PrivateVapidKeyEditableMsg
                            (adminData2.privateVapidKey |> (\(PrivateVapidKey a) -> a))
                            model.privateVapidKey
                        ]

                IsNotAdmin ->
                    Ui.none
            , TwoFactorAuthentication.view local.localUser.userAgent isMobile time loggedIn.twoFactor
                |> Ui.map TwoFactorMsg
            , MyUi.container
                isMobile
                "Miscellaneous"
                [ Editable.view
                    (Dom.id "userOptions_name")
                    False
                    "Display Name"
                    PersonName.fromString
                    UserNameEditableMsg
                    (PersonName.toString local.localUser.user.name)
                    model.name
                , Ui.column
                    []
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
                    , Html.a
                        [ Html.Attributes.href "settings-navigation://com.apple.Settings.Apps"
                        ]
                        [ Html.text "settings-navigation://com.apple.Settings.Apps" ]
                        |> Ui.html
                    , Html.a
                        [ Html.Attributes.href "App-prefs:com.apple.MobileSMS"
                        ]
                        [ Html.text "App-prefs:com.apple.MobileSMS" ]
                        |> Ui.html
                    , Html.a
                        [ Html.Attributes.href "prefs:NOTIFICATIONS_ID"
                        ]
                        [ Html.text "prefs:NOTIFICATIONS_ID" ]
                        |> Ui.html
                    , Html.a
                        [ Html.Attributes.href "prefs:root=NOTIFICATIONS_ID"
                        ]
                        [ Html.text "prefs:root=NOTIFICATIONS_ID" ]
                        |> Ui.html
                    , case local.localUser.session.pushSubscription of
                        NotSubscribed ->
                            Ui.none

                        Subscribed _ ->
                            Ui.none

                        SubscriptionError error ->
                            MyUi.errorBox
                                (Dom.id "userOptions_pushNotificationError")
                                PressedCopyText
                                (Log.httpErrorToString error)
                    ]
                , Ui.el
                    [ Ui.linkNewTab
                        (Slack.buildOAuthUrl
                            { clientId = Env.slackClientId
                            , redirectUri = Slack.redirectUri
                            , botScopes =
                                Nonempty
                                    "channels:read"
                                    [ "channels:history"
                                    , "users:read"
                                    , "team:read"
                                    ]
                            , userScopes =
                                Nonempty
                                    "channels:read"
                                    [ "channels:history"
                                    , "channels:write"
                                    , "groups:read"
                                    , "groups:history"
                                    , "groups:write"
                                    , "mpim:read"
                                    , "mpim:history"
                                    , "mpim:write"
                                    , "im:read"
                                    , "im:history"
                                    , "im:write"
                                    ]
                            , state = Lamdera.sessionIdToString loggedIn.sessionId
                            }
                        )
                    ]
                    (Ui.text "Link Slack account")
                ]
            , Ui.el
                [ Ui.paddingXY 16 0, Ui.width Ui.shrink ]
                (MyUi.simpleButton
                    (Dom.id "options_logout")
                    PressedLogOut
                    (Ui.row
                        [ Ui.spacing 8, Ui.paddingWith { left = 0, top = 0, bottom = 0, right = 8 } ]
                        [ Ui.el [ Ui.width (Ui.px 26) ] (Ui.html Icons.logoutSvg)
                        , Ui.text "Logout"
                        ]
                    )
                )
            ]
        )
