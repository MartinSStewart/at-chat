module UserOptions exposing (discordBookmarkletId, init, view)

import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import EmailAddress
import Env
import Html.Attributes
import Icons
import Id exposing (AnyGuildOrDmId, ThreadRoute)
import ImageEditor
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (AdminStatus(..), LocalState, PrivateVapidKey(..))
import Log
import MyUi
import PersonName
import Route
import SeqDict
import SessionIdHash
import Slack
import Time
import TwoFactorAuthentication
import Types exposing (FrontendMsg(..), LinkDiscordSubmitStatus(..), LoadedFrontend, LoggedIn2, UserOptionsModel)
import Ui exposing (Element)
import Ui.Events
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
                        MyUi.background1
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
                MyUi.background1
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
                    [ Ui.el [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ] (Ui.text "Profile Picture")
                    , Ui.row
                        [ Ui.spacing 12, Ui.alignLeft ]
                        [ User.profileImage local.localUser.user.icon
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

                        Subscribed _ ->
                            Ui.none

                        SubscriptionError error ->
                            MyUi.errorBox
                                (Dom.id "userOptions_pushNotificationError")
                                PressedCopyText
                                (Log.httpErrorToString error)
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
                , if SeqDict.isEmpty local.localUser.linkedDiscordUsers then
                    Ui.none

                  else
                    Ui.column
                        [ Ui.spacing 8 ]
                        [ Ui.el [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ] (Ui.text "Linked Discord users")
                        , Ui.column
                            [ Ui.spacing 8 ]
                            (List.map
                                (\( discordUserId, data ) ->
                                    Ui.column
                                        [ Ui.spacing 8
                                        , Ui.padding 12
                                        , Ui.border 1
                                        , Ui.borderColor MyUi.border1
                                        , Ui.rounded 8
                                        , Ui.widthMax 400
                                        ]
                                        [ Ui.row
                                            [ Ui.spacing 8, Ui.width Ui.fill ]
                                            [ User.profileImage data.icon
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
                                            [ MyUi.elButton
                                                (Dom.id ("userOptions_relinkDiscord_" ++ PersonName.toString data.name))
                                                PressedLinkDiscord
                                                [ Ui.borderColor MyUi.buttonBorder
                                                , Ui.border 1
                                                , Ui.background MyUi.buttonBackground
                                                , Ui.Font.color MyUi.font1
                                                , Ui.width Ui.shrink
                                                , Ui.paddingXY 12 6
                                                , Ui.rounded 4
                                                , Ui.Font.size 14
                                                ]
                                                (Ui.text "Relink")
                                            , MyUi.elButton
                                                (Dom.id ("userOptions_unlinkDiscord_" ++ PersonName.toString data.name))
                                                (PressedUnlinkDiscordUser discordUserId)
                                                [ Ui.border 1
                                                , Ui.borderColor (Ui.rgb 180 50 40)
                                                , Ui.background MyUi.deleteButtonBackground
                                                , Ui.Font.color MyUi.deleteButtonFont
                                                , Ui.width Ui.shrink
                                                , Ui.paddingXY 12 6
                                                , Ui.rounded 4
                                                , Ui.Font.size 14
                                                ]
                                                (Ui.text "Unlink")
                                            ]
                                        ]
                                )
                                (SeqDict.toList local.localUser.linkedDiscordUsers)
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
                        [ Ui.column
                            [ Ui.spacing 4 ]
                            [ Ui.text "To link your Discord account:"
                            , Ui.text "1. Copy the bookmarklet URL below"
                            , Ui.text "2. Create a new bookmark in your browser"
                            , Ui.text "3. Paste the URL as the bookmark address"
                            , Ui.text "4. Open Discord in your browser and click the bookmark"
                            ]
                        , Ui.column
                            [ Ui.spacing 2, Ui.widthMax 400 ]
                            [ bookmarkletLabel.element
                            , Ui.row
                                []
                                [ Ui.Input.text
                                    [ Ui.clipWithEllipsis
                                    , Ui.paddingWith { left = 8, right = 0, top = 2, bottom = 2 }
                                    , Ui.htmlAttribute (Html.Attributes.readonly True)
                                    , Ui.background MyUi.background1
                                    , Ui.border 1
                                    , Ui.borderColor MyUi.inputBorder
                                    , Ui.roundedWith { topLeft = 4, topRight = 0, bottomLeft = 4, bottomRight = 0 }
                                    , Ui.height Ui.fill
                                    , Ui.Events.onFocus (TextInputGotFocus discordBookmarkletId)
                                    ]
                                    { onChange = \_ -> TypedDiscordLinkBookmarklet
                                    , text = bookmarklet
                                    , placeholder = Nothing
                                    , label = bookmarkletLabel.id
                                    }
                                , MyUi.elButton
                                    (Dom.id "userOptions_copyBookmarklet")
                                    (PressedCopyText bookmarklet)
                                    [ Ui.width Ui.shrink
                                    , Ui.paddingWith { left = 4, right = 4, top = 2, bottom = 2 }
                                    , Ui.borderColor MyUi.inputBorder
                                    , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
                                    , Ui.roundedWith { topLeft = 0, topRight = 4, bottomLeft = 0, bottomRight = 4 }
                                    , Ui.spacing 4
                                    , Ui.background MyUi.buttonBackground
                                    , Ui.Font.size 14
                                    , Ui.height Ui.fill
                                    , Ui.contentCenterY
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
                            ]
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
                MyUi.background1
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
