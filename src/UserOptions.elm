module UserOptions exposing (view)

import Editable
import Effect.Browser.Dom as Dom
import Icons
import LocalState exposing (AdminStatus(..), IsEnabled(..), LocalState)
import MyUi
import PersonName
import Time
import TwoFactorAuthentication
import Types exposing (FrontendMsg(..), LoggedIn2, UserOptionsModel)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Input


view : Bool -> Time.Posix -> LocalState -> LoggedIn2 -> UserOptionsModel -> Element FrontendMsg
view isMobile time local loggedIn model =
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
                , Ui.el
                    [ Ui.padding 16
                    , Ui.width (Ui.px 56)
                    , Ui.Input.button PressedCloseUserOptions
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
                        label : { element : Element msg, id : Ui.Input.Label }
                        label =
                            Ui.Input.label "websocketEnabled" [] (Ui.text "Discord websocket enabled")
                    in
                    Ui.row
                        [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                        [ Ui.Input.checkbox
                            []
                            { onChange =
                                \isEnabled ->
                                    PressedSetDiscordWebsocket
                                        (if isEnabled then
                                            IsEnabled

                                         else
                                            IsDisabled
                                        )
                            , icon = Nothing
                            , checked = adminData2.websocketEnabled == IsEnabled
                            , label = label.id
                            }
                        , label.element
                        ]

                IsNotAdmin ->
                    Ui.none
            , TwoFactorAuthentication.view isMobile time loggedIn.twoFactor
                |> Ui.map TwoFactorMsg
            , Editable.view
                (Dom.id "userOptions_name")
                "Display Name"
                PersonName.fromString
                UserNameEditableMsg
                (PersonName.toString local.localUser.user.name)
                model.name
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
