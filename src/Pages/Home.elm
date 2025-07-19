module Pages.Home exposing
    ( header
    , loginButtonId
    , view
    )

import Effect.Browser.Dom as Dom exposing (HtmlId)
import Html.Attributes
import MyUi
import Types exposing (FrontendMsg(..), LoginStatus(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Input
import Ui.Shadow


header : LoginStatus -> Element FrontendMsg
header loginStatus =
    Ui.el
        [ Ui.background MyUi.background2
        , Ui.Shadow.shadows [ { x = 0, y = 1, blur = 2, size = 0, color = Ui.rgba 0 0 0 0.05 } ]
        ]
        (Ui.row
            [ Html.Attributes.style "padding" (MyUi.insetTop ++ " 16px 0 16px") |> Ui.htmlAttribute
            , Ui.contentCenterY
            , MyUi.montserrat
            , Ui.widthMax 1280
            , Ui.centerX
            ]
            [ Ui.image
                [ Ui.width (Ui.px 64), Ui.padding 8 ]
                { source = "/at-logo-no-background.png"
                , description = "Logo"
                , onLoad = Nothing
                }
            , case loginStatus of
                LoggedIn _ ->
                    Ui.none

                NotLoggedIn _ ->
                    Ui.el
                        ([ Ui.Input.button PressedShowLogin
                         , Dom.idToString loginButtonId |> Ui.id
                         ]
                            ++ buttonAttributes
                        )
                        (Ui.text "Login/Signup")
            ]
        )


buttonAttributes : List (Ui.Attribute msg)
buttonAttributes =
    [ Ui.Anim.hovered (Ui.Anim.ms 10) [ Ui.Anim.backgroundColor (Ui.rgb 69 83 124) ]
    , Ui.Font.weight 600
    , Ui.rounded 8
    , Ui.padding 8
    , Ui.alignRight
    ]


loginButtonId : HtmlId
loginButtonId =
    Dom.id "homePage_loginButton"


view : Int -> Element FrontendMsg
view windowWidth =
    Ui.column
        [ MyUi.montserrat
        , if windowWidth < 800 then
            Ui.paddingWith { left = 24, right = 24, top = 120, bottom = 48 }

          else
            Ui.paddingWith { left = 48, right = 48, top = 120, bottom = 48 }
        , Ui.widthMax 1280
        , Ui.centerX
        ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text "at-chat, a place to chat with friends")
        ]
