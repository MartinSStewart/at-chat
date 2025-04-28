module Pages.Home exposing
    ( header
    , loginButtonId
    , view
    )

import Effect.Browser.Dom as Dom exposing (HtmlId)
import MyUi
import Route exposing (Route(..), UserOverviewRouteData(..))
import Types exposing (FrontendMsg(..), LoginStatus(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Input
import Ui.Shadow


header : Int -> LoginStatus -> Element FrontendMsg
header windowWidth loginStatus =
    Ui.el
        [ Ui.background (Ui.rgb 255 255 255)
        , Ui.Shadow.shadows [ { x = 0, y = 1, blur = 2, size = 0, color = Ui.rgba 0 0 0 0.05 } ]
        ]
        (Ui.row
            [ if windowWidth < 800 then
                Ui.paddingXY 24 16

              else
                Ui.paddingXY 48 16
            , Ui.contentCenterY
            , MyUi.montserrat
            , Ui.widthMax 1280
            , Ui.centerX
            ]
            [ Ui.text "A logo would fit nicely here"
            , case loginStatus of
                LoggedIn _ ->
                    Ui.el
                        (Ui.Input.button
                            (PressedLink
                                (UserOverviewRoute PersonalRoute)
                            )
                            :: MyUi.touchPress
                                (PressedLink
                                    (UserOverviewRoute PersonalRoute)
                                )
                            :: Ui.id (Dom.idToString openDashboardButtonId)
                            :: buttonAttributes
                        )
                        (Ui.text "Open Dashboard")

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


openDashboardButtonId : HtmlId
openDashboardButtonId =
    Dom.id "homePage_openDashboardButton"


buttonAttributes : List (Ui.Attribute msg)
buttonAttributes =
    [ Ui.Font.color (Ui.rgb 113 128 150)
    , Ui.Anim.hovered (Ui.Anim.ms 10) [ Ui.Anim.backgroundColor (Ui.rgb 247 250 252) ]
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
            Ui.paddingWith { left = 24, right = 24, top = 96, bottom = 48 }

          else
            Ui.paddingWith { left = 48, right = 48, top = 120, bottom = 48 }
        , Ui.widthMax 1280
        , Ui.centerX
        ]
        [ Ui.el [ Ui.Font.size 48 ] (Ui.text "Your very own website!")
        ]
