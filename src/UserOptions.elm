module UserOptions exposing (init, view)

import Editable
import Effect.Browser.Dom as Dom
import Env
import Icons
import Id exposing (AnyGuildOrDmId, GuildOrDmId, ThreadRoute)
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (AdminStatus(..), LocalState, PrivateVapidKey(..))
import Log
import MyUi
import PersonName
import SeqDict
import SessionIdHash
import Slack
import Time
import TwoFactorAuthentication
import Types exposing (FrontendMsg(..), LinkDiscordSubmitStatus(..), LoadedFrontend, LoggedIn2, UserOptionsModel)
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import User
import UserAgent exposing (Browser(..), Device(..), UserAgent)
import UserSession exposing (NotificationMode(..), PushSubscription(..))


init : UserOptionsModel
init =
    { name = Editable.init
    , slackClientSecret = Editable.init
    , publicVapidKey = Editable.init
    , privateVapidKey = Editable.init
    , openRouterKey = Editable.init
    , showLinkDiscordSetup = False
    , linkDiscordSubmit = LinkDiscordNotSubmitted { attemptCount = 0 }
    }


viewConnectedDevice :
    Bool
    ->
        { a
            | notificationMode : NotificationMode
            , currentlyViewing : Maybe ( AnyGuildOrDmId, ThreadRoute )
            , userAgent : UserAgent
        }
    -> Element FrontendMsg
viewConnectedDevice isCurrentSession session =
    let
        browserText : String
        browserText =
            case session.userAgent.browser of
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
            case session.userAgent.device of
                Desktop ->
                    "Desktop"

                Mobile ->
                    "Mobile"

                Tablet ->
                    "Tablet"

        currentActivity : String
        currentActivity =
            case session.currentlyViewing of
                Just _ ->
                    "Active"

                Nothing ->
                    "Idle"
    in
    Ui.row
        [ Ui.spacing 8
        , Ui.width Ui.fill
        ]
        [ Ui.el
            [ Ui.width (Ui.px 36)
            , Ui.height (Ui.px 36)
            ]
            (case session.userAgent.device of
                Desktop ->
                    Ui.html Icons.desktop

                Mobile ->
                    Ui.html Icons.mobile

                Tablet ->
                    Ui.html Icons.tablet
            )
        , Ui.column
            [ Ui.spacing 2, Ui.width Ui.fill ]
            [ Ui.text
                (deviceText
                    ++ " • "
                    ++ browserText
                    ++ (if isCurrentSession then
                            " (current device)"

                        else
                            ""
                       )
                )
            , Ui.el
                [ Ui.Font.size 14
                , Ui.Font.color (Ui.rgb 128 128 128)
                ]
                (Ui.text currentActivity)
            ]
        ]


view : Bool -> Time.Posix -> LocalState -> LoggedIn2 -> LoadedFrontend -> UserOptionsModel -> Element FrontendMsg
view isMobile time local loggedIn loaded model =
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
                        , Editable.view
                            (Dom.id "userOptions_openRouterKey")
                            True
                            "OpenRouter API key"
                            (\text ->
                                let
                                    text2 =
                                        String.trim text
                                in
                                if text2 == "" then
                                    Ok Nothing

                                else
                                    Just text2 |> Ok
                            )
                            OpenRouterKeyEditableMsg
                            (case adminData2.openRouterKey of
                                Just key ->
                                    key

                                Nothing ->
                                    ""
                            )
                            model.openRouterKey
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
                    [ Ui.spacing 8 ]
                    [ Ui.el [ Ui.Font.size 14, Ui.Font.color (Ui.rgb 128 128 128) ] (Ui.text "Profile Picture")
                    , Ui.row
                        [ Ui.spacing 12, Ui.alignLeft ]
                        [ User.profileImage local.localUser.user.icon
                        , MyUi.simpleButton
                            (Dom.id "userOptions_changeProfilePicture")
                            PressedChangeProfilePicture
                            (Ui.text "Change profile picture")
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
                            , state = SessionIdHash.toString local.localUser.session.sessionIdHash
                            }
                        )
                    ]
                    (Ui.text "Link Slack account")

                --, Ui.column
                --    []
                --    (SeqDict.toList local.localUser.user.linkedDiscordUsers
                --        |> List.map
                --            (\( _, data ) ->
                --                Ui.text data.name
                --            )
                --    )
                , if model.showLinkDiscordSetup then
                    Ui.column
                        [ Ui.spacing 16, Ui.widthMax 400 ]
                        [ Ui.row
                            [ Ui.border 1
                            , Ui.borderColor MyUi.border1
                            , Ui.rounded 2
                            , Ui.spacing 8
                            , Ui.Font.color MyUi.font3
                            ]
                            [ Ui.el
                                [ Ui.clipWithEllipsis
                                , Ui.paddingWith { left = 8, right = 0, top = 2, bottom = 2 }
                                ]
                                (Ui.text bookmarklet)
                            , MyUi.elButton
                                (Dom.id "userOptions_copyBookmarklet")
                                (PressedCopyText bookmarklet)
                                [ Ui.width Ui.shrink
                                , Ui.paddingWith { left = 4, right = 4, top = 2, bottom = 2 }
                                , Ui.borderColor MyUi.border1
                                , Ui.borderWith { left = 1, right = 0, top = 0, bottom = 0 }
                                , Ui.spacing 4
                                ]
                                (case loaded.lastCopied of
                                    Just copied ->
                                        if copied.copiedText == bookmarklet then
                                            Ui.text "Copied!"

                                        else
                                            Ui.html Icons.copy

                                    Nothing ->
                                        Ui.html Icons.copy
                                )
                            ]
                        , Ui.Input.multiline
                            [ Ui.inFront
                                (Ui.el
                                    [ Ui.centerX
                                    , Ui.centerY
                                    , Ui.Font.center
                                    , MyUi.noPointerEvents
                                    , Ui.paddingXY 16 8
                                    ]
                                    (case model.linkDiscordSubmit of
                                        LinkDiscordNotSubmitted { attemptCount } ->
                                            Ui.text "After running the bookmarklet, paste the contents of your clipboard here."

                                        LinkDiscordSubmitting ->
                                            Ui.text "Submitting..."

                                        LinkDiscordSubmitted ->
                                            Ui.text "Linked!"
                                    )
                                )
                            , Ui.height (Ui.px 150)
                            , Ui.background MyUi.inputBackground
                            , Ui.borderColor MyUi.inputBorder
                            ]
                            { onChange = TypedBookmarkletData
                            , text = ""
                            , placeholder = Nothing
                            , label = Ui.Input.labelHidden "userOptions_pasteBookmarkletData"
                            , spellcheck = False
                            }
                        ]

                  else
                    MyUi.elButton
                        (Dom.id "userOptions_linkDiscord")
                        PressedLinkDiscord
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
                isMobile
                "Connected devices"
                (viewConnectedDevice True local.localUser.session :: List.map (viewConnectedDevice False) (SeqDict.values local.otherSessions))
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
    navigator.clipboard.writeText(data);

    alert("Data copied to clipboard. Go back to at-chat and paste it there.");
})()"""
        |> String.replace "\n" " "
        |> String.replace "  " " "
        |> String.replace "  " " "
        |> String.replace "  " " "
