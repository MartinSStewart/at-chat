module UserColor exposing (Selection, UserColor(..), default, picked, picker, startPicking, toColor, toStyle)

import Color
import Effect.Browser.Dom as Dom
import MyUi
import Ui
import Ui.Events
import Ui.Font
import Ui.Input


{-| OpaqueVariants
-}
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


{-| Where the brightness slider is, and the last colour it passed over that could actually be
used.

Those come apart when the slider is taken past the point where the chosen square stops being
readable. The square is struck out to say so, and `lastValid` is what carries on being
previewed and saved, so nobody ends up with a colour they can't see.

-}
type alias Selection =
    { selected : UserColor, lastValid : UserColor }


startPicking : UserColor -> Selection
startPicking color =
    { selected = color, lastValid = color }


{-| The colour a selection actually stands for, which is the last usable one it landed on.
-}
picked : Selection -> UserColor
picked selection =
    selection.lastValid


select : Selection -> UserColor -> Selection
select selection color =
    { selected = color
    , lastValid =
        if isReadable (toColor color) then
            color

        else
            selection.lastValid
    }


picker : Bool -> Selection -> (Selection -> msg) -> Ui.Element msg
picker isMobile selection onChange =
    let
        parts : { hue : Int, saturation : Int, lightness : Int }
        parts =
            toParts selection.selected

        swatchView2 : Ui.Element msg
        swatchView2 =
            Ui.row
                [ Ui.wrap ]
                (List.map
                    (swatchView isMobile selection parts onChange)
                    (List.range 0 (hueCount * saturationCount - 1))
                )
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
            [ lightnessSlider selection parts onChange
            , swatchView2
            ]

         else
            [ swatchView2
            , lightnessSlider selection parts onChange
            ]
        )


swatchId : Int -> Dom.HtmlId
swatchId index =
    Dom.id ("userColor_swatch_" ++ String.fromInt index)


swatchView :
    Bool
    -> Selection
    -> { hue : Int, saturation : Int, lightness : Int }
    -> (Selection -> msg)
    -> Int
    -> Ui.Element msg
swatchView isMobile selection selected onChange index =
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

        usable : Bool
        usable =
            isReadable color
    in
    Ui.el
        (Ui.id (Dom.idToString (swatchId index))
            :: Ui.width swatchSize2
            :: Ui.height swatchSize2
            :: (if usable then
                    [ Ui.background color
                    , Ui.Events.onClick (onChange (select selection userColor))
                    , MyUi.htmlStyle "cursor" "pointer"
                    ]

                else
                    []
               )
            ++ (if hue == selected.hue && saturation == selected.saturation then
                    [ Ui.inFront (selectionOutline usable) ]

                else
                    []
               )
        )
        Ui.none


{-| The ring around the square the picker is pointing at. Black reads against every colour
the grid offers, since they all have to be light enough to be used in the first place.

A square the brightness slider has taken out of reach has nothing drawn in it, so there the
ring has to stand out against the panel behind it instead, and a line struck across says the
square isn't on offer at this brightness.

-}
selectionOutline : Bool -> Ui.Element msg
selectionOutline usable =
    Ui.el
        (Ui.border 2
            :: Ui.height Ui.fill
            :: (if usable then
                    [ Ui.borderColor MyUi.black ]

                else
                    [ Ui.borderColor MyUi.white
                    , MyUi.htmlStyle "background-image" struckOutLine
                    ]
               )
        )
        Ui.none


struckOutLine : String
struckOutLine =
    let
        line : String
        line =
            MyUi.colorToStyle MyUi.white
    in
    "linear-gradient(to top right, transparent calc(50% - 1px), "
        ++ line
        ++ " calc(50% - 1px), "
        ++ line
        ++ " calc(50% + 1px), transparent calc(50% + 1px))"


lightnessSlider :
    Selection
    -> { hue : Int, saturation : Int, lightness : Int }
    -> (Selection -> msg)
    -> Ui.Element msg
lightnessSlider selection parts onChange =
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
            , onChange =
                \value -> select selection (fromParts { parts | lightness = round value }) |> onChange
            , min = 5
            , max = toFloat (lightnessCount - 1) - 2
            , value = toFloat parts.lightness
            , thumb = Nothing
            , step = Just 1
            }
        ]
