module UserColor exposing (UserColor, default, picker)

import Color.Convert
import MyUi
import Ui


type UserColor
    = UserColor Int


default : UserColor
default =
    UserColor 0


contrastColor =
    Color.Convert.colorToLab MyUi.background2


distance : { l : Float, a : Float, b : Float } -> { l : Float, a : Float, b : Float } -> Float
distance labA labB =
    (labA.l - labB.l) ^ 2 + (labA.a - labB.a) ^ 2 + (labA.b - labB.b) ^ 2 |> sqrt


picker : Ui.Element msg
picker =
    Ui.row
        [ Ui.wrap
        , Ui.width (Ui.px 100)
        ]
        (List.map
            (\index ->
                let
                    x : Int
                    x =
                        modBy 10 index

                    y : Int
                    y =
                        index // 10

                    color : Ui.Color
                    color =
                        Ui.rgb ((x * 255) // 10) ((y * 255) // 10) 100
                in
                Ui.el
                    [ Ui.width (Ui.px 10)
                    , Ui.height (Ui.px 10)
                    , if distance (Color.Convert.colorToLab color) contrastColor < 100 then
                        Ui.noAttr

                      else
                        Ui.background color
                    ]
                    Ui.none
            )
            (List.range 0 99)
        )
