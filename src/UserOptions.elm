module UserOptions exposing (view)

import Effect.Browser.Dom as Dom
import Icons
import LocalState exposing (AdminStatus(..), IsEnabled(..), LocalState)
import LoginForm exposing (CodeStatus(..))
import MyUi
import QRCode
import SeqDict
import Time
import TwoFactorAuthentication
import Types exposing (FrontendMsg(..), LoggedIn2)
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Prose


view : Time.Posix -> LocalState -> LoggedIn2 -> Element FrontendMsg
view time local loggedIn =
    Ui.el
        [ Ui.height Ui.fill
        , Ui.background MyUi.background1
        , Ui.inFront
            (Ui.el
                [ Ui.padding 16
                , Ui.width (Ui.px 56)
                , Ui.Input.button PressedCloseUserOptions
                , Ui.alignRight
                ]
                (Ui.html Icons.x)
            )
        ]
        (Ui.column
            [ Ui.padding 16
            ]
            [ case local.adminData of
                IsAdmin adminData2 ->
                    let
                        label : { element : Element msg, id : Ui.Input.Label }
                        label =
                            Ui.Input.label "websocketEnabled" [] (Ui.text "Discord websocket enabled")
                    in
                    Ui.row
                        [ Ui.spacing 8 ]
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
            , TwoFactorAuthentication.twoFactor time loggedIn.twoFactor
                |> Ui.map TwoFactorMsg
            ]
        )
