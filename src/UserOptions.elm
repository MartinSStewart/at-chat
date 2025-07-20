module UserOptions exposing (view)

import Html.Attributes
import Icons
import LocalState exposing (AdminStatus(..), IsEnabled(..), LocalState)
import MyUi
import Time
import TwoFactorAuthentication
import Types exposing (FrontendMsg(..), LoggedIn2)
import Ui exposing (Element)
import Ui.Font
import Ui.Input


view : Bool -> Time.Posix -> LocalState -> LoggedIn2 -> Element FrontendMsg
view isMobile time local loggedIn =
    Ui.el
        [ Ui.height Ui.fill
        , Ui.background MyUi.background1
        , Ui.inFront
            (Ui.row
                [ Ui.background MyUi.background1
                , Html.Attributes.style "padding-top" MyUi.insetTop
                    |> Ui.htmlAttribute
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
            [ Html.Attributes.style
                "padding"
                ("calc(80px + " ++ MyUi.insetTop ++ ") 0 calc(24px + " ++ MyUi.insetBottom ++ ") 0")
                |> Ui.htmlAttribute

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
            ]
        )
