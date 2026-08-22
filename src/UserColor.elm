module UserColor exposing (UserColor, default, picker, toColor, toStyle)

import Color
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
    12


lightnessCount : number
lightnessCount =
    16


swatchSize : Bool -> Int
swatchSize isMobile =
    if isMobile then
        18

    else
        20


default : UserColor
default =
    fromParts
        { hue = 0
        , saturation = 0
        , lightness = 11
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


toStyle : UserColor -> String
toStyle userColor =
    let
        parts =
            toParts userColor
    in
    "hsl("
        ++ String.fromFloat (360 * toFloat parts.hue / toFloat hueCount)
        ++ " "
        ++ String.fromFloat (100 * toFloat parts.saturation / toFloat (saturationCount - 1))
        ++ " "
        ++ String.fromFloat (100 * toFloat parts.lightness / toFloat (lightnessCount - 1))
        ++ ")"


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


picker : Bool -> UserColor -> (UserColor -> msg) -> Ui.Element msg
picker isMobile selected onChange =
    let
        parts : { hue : Int, saturation : Int, lightness : Int }
        parts =
            toParts selected

        swatchView2 : Ui.Element msg
        swatchView2 =
            Ui.row
                [ Ui.wrap ]
                (List.map (swatchView isMobile parts onChange) (List.range 0 (hueCount * saturationCount - 1)))
    in
    Ui.column
        [ Ui.spacing 8
        , Ui.width
            (Ui.px
                (if isMobile then
                    swatchSize isMobile * saturationCount

                 else
                    swatchSize isMobile * hueCount
                )
            )
        ]
        (if isMobile then
            [ lightnessSlider parts onChange
            , swatchView2
            ]

         else
            [ swatchView2
            , lightnessSlider parts onChange
            ]
        )


swatchId : Int -> Dom.HtmlId
swatchId index =
    Dom.id ("userColor_swatch_" ++ String.fromInt index)


swatchView : Bool -> { hue : Int, saturation : Int, lightness : Int } -> (UserColor -> msg) -> Int -> Ui.Element msg
swatchView isMobile selected onChange index =
    let
        hue : Int
        hue =
            if isMobile then
                index // saturationCount

            else
                modBy hueCount index

        saturation : Int
        saturation =
            if isMobile then
                modBy saturationCount index

            else
                index // hueCount

        userColor =
            fromParts { hue = hue, saturation = saturation, lightness = selected.lightness }

        color : Ui.Color
        color =
            toColor userColor

        swatchSize2 =
            swatchSize isMobile |> Ui.px
    in
    Ui.el
        (Ui.id (Dom.idToString (swatchId index))
            :: Ui.width swatchSize2
            :: Ui.height swatchSize2
            :: (if isReadable color then
                    [ Ui.background color
                    , Ui.Events.onClick (onChange userColor)
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
