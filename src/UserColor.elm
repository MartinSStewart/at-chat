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
    32


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


isReadable : Ui.Color -> Bool
isReadable color =
    isFontColorReadable color MyUi.background3


{-| APCA Lc 60 is roughly the perceptual equivalent of WCAG 2's 4.5:1 for body text.
Use 75 if you want comfortable reading, 45 for large or bold text.
-}
isFontColorReadable : Ui.Color -> Ui.Color -> Bool
isFontColorReadable fontColor backgroundColor =
    abs (apcaContrast fontColor backgroundColor) >= 30


{-| Lightness contrast (Lc), roughly -108 to 106.
Positive means dark text on a light background, negative the reverse.
-}
apcaContrast : Ui.Color -> Ui.Color -> Float
apcaContrast fontColor backgroundColor =
    let
        yText =
            screenLuminance fontColor

        yBg =
            screenLuminance backgroundColor
    in
    if abs (yBg - yText) < 0.0005 then
        0

    else if yBg > yText then
        let
            sapc =
                (yBg ^ 0.56 - yText ^ 0.57) * 1.14
        in
        if sapc < 0.1 then
            0

        else
            (sapc - 0.027) * 100

    else
        let
            sapc =
                (yBg ^ 0.65 - yText ^ 0.62) * 1.14
        in
        if sapc > -0.1 then
            0

        else
            (sapc + 0.027) * 100


screenLuminance : Ui.Color -> Float
screenLuminance color =
    let
        { red, green, blue } =
            Color.toRgba color

        y =
            0.2126729 * (red ^ 2.4) + 0.7151522 * (green ^ 2.4) + 0.072175 * (blue ^ 2.4)
    in
    -- Soft clamp near black, since dark colors compress perceptually
    if y < 0.022 then
        y + (0.022 - y) ^ 1.414

    else
        y


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
            , min = 3
            , max = toFloat (lightnessCount - 1) - 2
            , value = toFloat parts.lightness
            , thumb = Nothing
            , step = Just 1
            }
        ]
