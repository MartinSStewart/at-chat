module UserOptions exposing (init, view)

import Editable
import Effect.Browser.Dom as Dom
import Icons
import LocalState exposing (AdminStatus(..), DiscordBotToken(..), LocalState, PrivateVapidKey(..))
import MyUi
import PersonName
import Time
import TwoFactorAuthentication
import Types exposing (FrontendMsg(..), LoadedFrontend, LoggedIn2, UserOptionsModel)
import Ui exposing (Element)
import Ui.Font
import Ui.Input


init : UserOptionsModel
init =
    { name = Editable.init
    , botToken = Editable.init
    , publicVapidKey = Editable.init
    , privateVapidKey = Editable.init
    }


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
                    let
                        botToken : String
                        botToken =
                            case adminData2.botToken of
                                Just (DiscordBotToken a) ->
                                    a

                                Nothing ->
                                    ""
                    in
                    MyUi.container
                        isMobile
                        "Admin"
                        [ Editable.view
                            (Dom.id "userOptions_botToken")
                            True
                            "Bot token"
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
                            botToken
                            model.botToken
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
            , TwoFactorAuthentication.view isMobile time loggedIn.twoFactor
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
                , let
                    enablePushNotificationsLabel =
                        Ui.Input.label "userOptions_togglePushNotifications" [ Ui.padding 8 ] (Ui.text "Enable push notifications")
                  in
                  Ui.row
                    []
                    [ Ui.Input.checkbox
                        [ Ui.padding 8 ]
                        { onChange = ToggledEnablePushNotifications
                        , icon = Nothing
                        , checked = loaded.enabledPushNotifications
                        , label = enablePushNotificationsLabel.id
                        }
                    , enablePushNotificationsLabel.element
                    ]
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
