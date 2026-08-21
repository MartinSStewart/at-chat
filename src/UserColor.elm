module UserColor exposing (UserColor, default, picker, toColor)

import Color
import Color.Convert
import Effect.Browser.Dom as Dom
import MyUi
import Ui
import Ui.Events
import Ui.Font
import Ui.Input


type UserColor
    = UserColor Int


hueCount : number
hueCount =
    16


saturationCount : number
saturationCount =
    16


lightnessCount : number
lightnessCount =
    16


swatchSize : Int
swatchSize =
    20


default : UserColor
default =
    let
        { hue, saturation, lightness } =
            Color.toHsla MyUi.font1
    in
    fromParts
        { hue = round (hueCount * hue)
        , saturation = round (saturationCount * saturation)
        , lightness = round (lightnessCount * lightness)
        }


fromParts : { hue : Int, saturation : Int, lightness : Int } -> UserColor
fromParts parts =
    modBy hueCount parts.hue
        + (modBy saturationCount parts.saturation * hueCount)
        + (modBy lightnessCount parts.lightness * hueCount * saturationCount)
        |> UserColor


{-| Nothing stops a client from sending a number that isn't a colour, so this wraps rather
than trusting what it's given.
-}
toParts : UserColor -> { hue : Int, saturation : Int, lightness : Int }
toParts (UserColor index) =
    let
        wrapped : Int
        wrapped =
            modBy (hueCount * saturationCount * lightnessCount) index
    in
    { hue = modBy hueCount wrapped
    , saturation = modBy saturationCount (wrapped // hueCount)
    , lightness = wrapped // (hueCount * saturationCount)
    }


{-| The grid never offers pure black or pure white, and never a colour with no colour left in
it, since none of those are much use for telling players apart. The ends of the lightness
slider stop short of both for the same reason: past them every square fails the readability
check below and the grid comes out empty.
-}
toColor : UserColor -> Ui.Color
toColor userColor =
    let
        parts : { hue : Int, saturation : Int, lightness : Int }
        parts =
            toParts userColor
    in
    Color.hsl
        (toFloat parts.hue / toFloat hueCount)
        (toFloat parts.saturation / toFloat (saturationCount - 1))
        (toFloat parts.lightness / toFloat (lightnessCount - 1))


background2 : { l : Float, a : Float, b : Float }
background2 =
    Color.Convert.colorToLab MyUi.background2


background3 : { l : Float, a : Float, b : Float }
background3 =
    Color.Convert.colorToLab MyUi.background2


alertColor : { l : Float, a : Float, b : Float }
alertColor =
    Color.Convert.colorToLab MyUi.alertColor


distance : { l : Float, a : Float, b : Float } -> { l : Float, a : Float, b : Float } -> Float
distance labA labB =
    (labA.l - labB.l) ^ 2 + (labA.a - labB.a) ^ 2 + (labA.b - labB.b) ^ 2 |> sqrt


isReadable : Ui.Color -> Bool
isReadable color =
    (distance (Color.Convert.colorToLab color) background2 >= 80)
        && (distance (Color.Convert.colorToLab color) background3 >= 80)
        && (distance (Color.Convert.colorToLab color) alertColor >= 20)


picker : UserColor -> (UserColor -> msg) -> Ui.Element msg
picker selected onChange =
    let
        parts : { hue : Int, saturation : Int, lightness : Int }
        parts =
            toParts selected
    in
    Ui.column
        [ Ui.spacing 8, Ui.width (Ui.px (swatchSize * hueCount)) ]
        [ Ui.row
            [ Ui.wrap ]
            (List.map (swatchView parts onChange) (List.range 0 (hueCount * saturationCount - 1)))
        , lightnessSlider parts onChange
        ]


swatchId : Int -> Dom.HtmlId
swatchId index =
    Dom.id ("userColor_swatch_" ++ String.fromInt index)


swatchView : { hue : Int, saturation : Int, lightness : Int } -> (UserColor -> msg) -> Int -> Ui.Element msg
swatchView selected onChange index =
    let
        hue : Int
        hue =
            modBy hueCount index

        saturation : Int
        saturation =
            index // hueCount

        color : Ui.Color
        color =
            toColor (fromParts { hue = hue, saturation = saturation, lightness = selected.lightness })
    in
    Ui.el
        (Ui.id (Dom.idToString (swatchId index))
            :: Ui.width (Ui.px swatchSize)
            :: Ui.height (Ui.px swatchSize)
            :: (if isReadable color then
                    [ Ui.background color
                    , Ui.Events.onClick
                        (onChange
                            (fromParts
                                { hue = hue, saturation = saturation, lightness = selected.lightness }
                            )
                        )
                    , MyUi.htmlStyle "cursor" "pointer"
                    , if hue == selected.hue && saturation == selected.saturation then
                        Ui.inFront
                            (Ui.el
                                [ Ui.border 2
                                , Ui.borderColor MyUi.font1
                                , Ui.height Ui.fill
                                ]
                                Ui.none
                            )

                      else
                        Ui.noAttr
                    ]

                else
                    []
               )
        )
        Ui.none


lightnessSlider : { hue : Int, saturation : Int, lightness : Int } -> (UserColor -> msg) -> Ui.Element msg
lightnessSlider parts onChange =
    let
        sliderLabel : { element : Ui.Element msg, id : Ui.Input.Label }
        sliderLabel =
            MyUi.label
                (Dom.id "userColor_lightness")
                [ Ui.Font.color MyUi.font3, Ui.Font.size 14 ]
                (Ui.text "Brightness")
    in
    Ui.column
        [ Ui.spacing 2 ]
        [ sliderLabel.element
        , Ui.Input.sliderHorizontal
            [ Ui.background MyUi.background3
            , Ui.rounded 4
            ]
            { label = sliderLabel.id
            , onChange = \value -> onChange (fromParts { parts | lightness = round value })
            , min = 7
            , max = toFloat (lightnessCount - 1) - 5
            , value = toFloat parts.lightness
            , thumb = Nothing
            , step = Just 1
            }
        ]
