module UserOptions exposing (view)

import Icons
import MyUi
import Types exposing (FrontendMsg(..), LoggedIn2)
import Ui exposing (Element)
import Ui.Input


view : LoggedIn2 -> Element FrontendMsg
view loggedIn =
    Ui.column
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
        [ case loggedIn.admin of
            Just _ ->
                let
                    loginData = loggedIn.localState.localModel
                in
                Ui.Input.checkbox
                    { onChange = \_ -> PressedToggleDiscordWebsocket
                    , icon = Ui.Input.defaultCheckbox
                    , checked = loginData.discordWebsocketEnabled
                    , label = Ui.Input.labelRight [] (Ui.text "Enable Discord websocket")
                    }

            Nothing ->
                Ui.none
        ]
