module UserColor exposing (UserColor, default, picker)

import Color
import Color.Convert
import Effect.Browser.Dom as Dom
import MyUi
import Ui
import Ui.Events
import Ui.Font
import Ui.Input


{-| Which square of the picker's grid someone chose, and how far up the brightness slider it
sits. Kept as one number so that it's cheap to store and to send.
-}
type UserColor
    = UserColor Int


{-| How many hues the grid runs across, how many steps of colourfulness it runs down, and how
many stops the brightness slider has.
-}
hueCount : Int
hueCount =
    10


saturationCount : Int
saturationCount =
    10


brightnessCount : Int
brightnessCount =
    10


swatchSize : Int
swatchSize =
    20


default : UserColor
default =
    fromParts { hue = 0, saturation = saturationCount - 1, brightness = brightnessCount // 2 }


fromParts : { hue : Int, saturation : Int, brightness : Int } -> UserColor
fromParts parts =
    modBy hueCount parts.hue
        + (modBy saturationCount parts.saturation * hueCount)
        + (modBy brightnessCount parts.brightness * hueCount * saturationCount)
        |> UserColor


{-| Nothing stops a client from sending a number that isn't a colour, so this wraps rather
than trusting what it's given.
-}
toParts : UserColor -> { hue : Int, saturation : Int, brightness : Int }
toParts (UserColor index) =
    let
        wrapped : Int
        wrapped =
            modBy (hueCount * saturationCount * brightnessCount) index
    in
    { hue = modBy hueCount wrapped
    , saturation = modBy saturationCount (wrapped // hueCount)
    , brightness = wrapped // (hueCount * saturationCount)
    }


{-| The grid never offers pure black or pure white, and never a colour with no colour left in
it, since none of those are much use for telling players apart. The ends of the brightness
slider stop short of both for the same reason: past them every square fails the readability
check below and the grid comes out empty.
-}
toColor : UserColor -> Ui.Color
toColor userColor =
    let
        parts : { hue : Int, saturation : Int, brightness : Int }
        parts =
            toParts userColor
    in
    Color.hsl
        (toFloat parts.hue / toFloat hueCount)
        (0.5 + 0.5 * toFloat parts.saturation / toFloat (saturationCount - 1))
        (0.35 + 0.4 * toFloat parts.brightness / toFloat (brightnessCount - 1))


contrastColor : { l : Float, a : Float, b : Float }
contrastColor =
    Color.Convert.colorToLab MyUi.background2


distance : { l : Float, a : Float, b : Float } -> { l : Float, a : Float, b : Float } -> Float
distance labA labB =
    (labA.l - labB.l) ^ 2 + (labA.a - labB.a) ^ 2 + (labA.b - labB.b) ^ 2 |> sqrt


{-| A colour too close to what it's drawn against can't be read, so the grid leaves those
squares empty instead of offering them. Which squares those are depends on the brightness,
so the grid is redrawn as the slider moves.
-}
isReadable : Ui.Color -> Bool
isReadable color =
    distance (Color.Convert.colorToLab color) contrastColor >= 100


picker : UserColor -> (UserColor -> msg) -> Ui.Element msg
picker selected onChange =
    let
        parts : { hue : Int, saturation : Int, brightness : Int }
        parts =
            toParts selected
    in
    Ui.column
        [ Ui.spacing 8, Ui.width (Ui.px (swatchSize * hueCount)) ]
        [ Ui.row
            [ Ui.wrap ]
            (List.map (swatchView parts onChange) (List.range 0 (hueCount * saturationCount - 1)))
        , brightnessSlider parts onChange
        ]


swatchId : Int -> Dom.HtmlId
swatchId index =
    Dom.id ("userColor_swatch_" ++ String.fromInt index)


swatchView : { hue : Int, saturation : Int, brightness : Int } -> (UserColor -> msg) -> Int -> Ui.Element msg
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
            toColor (fromParts { hue = hue, saturation = saturation, brightness = selected.brightness })
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
                                { hue = hue, saturation = saturation, brightness = selected.brightness }
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


brightnessSlider : { hue : Int, saturation : Int, brightness : Int } -> (UserColor -> msg) -> Ui.Element msg
brightnessSlider parts onChange =
    let
        sliderLabel : { element : Ui.Element msg, id : Ui.Input.Label }
        sliderLabel =
            MyUi.label
                (Dom.id "userColor_brightness")
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
            , onChange = \value -> onChange (fromParts { parts | brightness = round value })
            , min = 0
            , max = toFloat (brightnessCount - 1)
            , value = toFloat parts.brightness
            , thumb = Nothing
            , step = Just 1
            }
        ]
