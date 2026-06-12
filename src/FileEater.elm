module FileEater exposing
    ( EatingFile
    , draggingView
    , eatingView
    , fadeInDelay
    , isFinished
    , position
    )

{-| A hungry creature that appears when the user takes too long deciding where to drop a file. It fades in after the drag has lasted a while, follows the cursor with a parallax effect, and eats the file when it gets dropped.
-}

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Duration)
import Effect.Time as Time
import Html exposing (Html)
import Html.Attributes
import Quantity
import Svg exposing (Svg)
import Svg.Attributes
import Ui exposing (Element)


type alias EatingFile =
    { start : Time.Posix
    , dropPosition : Coord CssPixels
    , eaterPosition : Coord CssPixels
    }


{-| How long files need to be dragged around before the eater starts fading in
-}
fadeInDelay : Duration
fadeInDelay =
    Duration.seconds 1


fadeInDuration : Duration
fadeInDuration =
    Duration.seconds 0.5


eatingDuration : Duration
eatingDuration =
    Duration.seconds 1.1


isFinished : Time.Posix -> EatingFile -> Bool
isFinished time eating =
    Duration.from eating.start time |> Quantity.greaterThanOrEqualTo eatingDuration


{-| The eater follows the cursor with a parallax effect: it only moves a fraction of the cursor's distance from the center of the window.
-}
position : Coord CssPixels -> Coord CssPixels -> Coord CssPixels
position windowSize mousePosition =
    Coord.xy
        (parallaxAxis (Coord.xRaw windowSize) (Coord.xRaw mousePosition))
        (parallaxAxis (Coord.yRaw windowSize) (Coord.yRaw mousePosition))


parallaxAxis : Int -> Int -> Int
parallaxAxis windowLength mouse =
    windowLength // 2 + round (toFloat (mouse - windowLength // 2) * 0.35)


draggingView : Time.Posix -> Coord CssPixels -> { a | dragOverStart : Time.Posix, mousePosition : Coord CssPixels } -> Element msg
draggingView time windowSize fileDrag =
    let
        elapsed : Duration
        elapsed =
            Duration.from fileDrag.dragOverStart time

        opacity : Float
        opacity =
            Quantity.ratio (elapsed |> Quantity.minus fadeInDelay) fadeInDuration |> clamp 0 1
    in
    if opacity <= 0 then
        Ui.none

    else
        Ui.html
            (eaterHtml
                { opacity = opacity
                , position = position windowSize fileDrag.mousePosition
                , bob = sin (Duration.inSeconds elapsed * 4) * 6
                , mouthOpen = 1
                , smoothFollow = True
                }
            )


eatingView : Time.Posix -> EatingFile -> Element msg
eatingView time eating =
    let
        t : Float
        t =
            Duration.from eating.start time |> Duration.inSeconds

        -- The mouth chomps shut twice while the file disappears into it
        mouthOpen : Float
        mouthOpen =
            if t < 0.3 then
                1

            else if t < 0.4 then
                interpolate 1 0.08 ((t - 0.3) / 0.1)

            else if t < 0.5 then
                interpolate 0.08 1 ((t - 0.4) / 0.1)

            else if t < 0.6 then
                interpolate 1 0.08 ((t - 0.5) / 0.1)

            else
                0.08

        opacity : Float
        opacity =
            clamp 0 1 (1 - (t - 0.7) / 0.4)
    in
    Ui.html
        (Html.div
            []
            [ eaterHtml
                { opacity = opacity
                , position = eating.eaterPosition
                , bob = 0
                , mouthOpen = mouthOpen
                , smoothFollow = False
                }
            , flyingFileHtml t eating
            ]
        )


interpolate : Float -> Float -> Float -> Float
interpolate start end t =
    start + (end - start) * t


{-| Where the center of the mouth ends up on screen, for the file to fly into
-}
mouthCenter : Coord CssPixels -> Coord CssPixels
mouthCenter eaterPosition =
    Coord.plus (Coord.xy (mouthCenterX - svgWidth // 2) (mouthCenterY - svgHeight // 2)) eaterPosition


flyingFileHtml : Float -> EatingFile -> Html msg
flyingFileHtml t eating =
    let
        -- Accelerate towards the mouth
        flyProgress : Float
        flyProgress =
            clamp 0 1 (t / 0.32) ^ 2

        target : Coord CssPixels
        target =
            mouthCenter eating.eaterPosition

        x : Float
        x =
            interpolate (toFloat (Coord.xRaw eating.dropPosition)) (toFloat (Coord.xRaw target)) flyProgress

        y : Float
        y =
            interpolate (toFloat (Coord.yRaw eating.dropPosition)) (toFloat (Coord.yRaw target)) flyProgress

        scale : Float
        scale =
            interpolate 1 0.2 flyProgress
    in
    if flyProgress >= 1 then
        Html.text ""

    else
        Html.div
            [ Html.Attributes.style "position" "fixed"
            , Html.Attributes.style "left" (String.fromFloat (x - 20) ++ "px")
            , Html.Attributes.style "top" (String.fromFloat (y - 25) ++ "px")
            , Html.Attributes.style "transform" ("scale(" ++ String.fromFloat scale ++ ")")
            , Html.Attributes.style "pointer-events" "none"
            ]
            [ fileSvg ]


eaterHtml :
    { opacity : Float
    , position : Coord CssPixels
    , bob : Float
    , mouthOpen : Float
    , smoothFollow : Bool
    }
    -> Html msg
eaterHtml config =
    Html.div
        ([ Html.Attributes.style "position" "fixed"
         , Html.Attributes.style "left" (String.fromInt (Coord.xRaw config.position - svgWidth // 2) ++ "px")
         , Html.Attributes.style "top" (String.fromInt (Coord.yRaw config.position - svgHeight // 2) ++ "px")
         , Html.Attributes.style "opacity" (String.fromFloat config.opacity)
         , Html.Attributes.style "pointer-events" "none"
         ]
            ++ (if config.smoothFollow then
                    [ Html.Attributes.style "transition" "left 0.1s linear, top 0.1s linear" ]

                else
                    []
               )
        )
        [ Html.div
            [ Html.Attributes.style "transform" ("translateY(" ++ String.fromFloat config.bob ++ "px)") ]
            [ eaterSvg config.mouthOpen ]
        ]


svgWidth : number
svgWidth =
    340


svgHeight : number
svgHeight =
    300


mouthCenterX : number
mouthCenterX =
    185


mouthCenterY : number
mouthCenterY =
    247


strokeColor : String
strokeColor =
    "#f4f4f4"


eaterSvg : Float -> Html msg
eaterSvg mouthOpen =
    Svg.svg
        [ Svg.Attributes.width (String.fromInt svgWidth)
        , Svg.Attributes.height (String.fromInt svgHeight)
        , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt svgWidth ++ " " ++ String.fromInt svgHeight)
        ]
        [ -- Left ear
          strokedPolyline "28,98 33,38 76,62"
        , -- Right ear
          strokedPolyline "262,62 303,38 308,90"
        , -- Left eye
          eye 96 126 23 16 -25
        , -- Right eye
          eye 238 110 17 13 -10
        , -- Mouth, squished vertically while chomping
          Svg.g
            [ Svg.Attributes.transform
                ("translate(0 "
                    ++ String.fromInt mouthCenterY
                    ++ ") scale(1 "
                    ++ String.fromFloat mouthOpen
                    ++ ") translate(0 -"
                    ++ String.fromInt mouthCenterY
                    ++ ")"
                )
            ]
            [ Svg.ellipse
                [ Svg.Attributes.cx (String.fromInt mouthCenterX)
                , Svg.Attributes.cy (String.fromInt mouthCenterY)
                , Svg.Attributes.rx "116"
                , Svg.Attributes.ry "36"
                , Svg.Attributes.transform ("rotate(-4 " ++ String.fromInt mouthCenterX ++ " " ++ String.fromInt mouthCenterY ++ ")")
                , Svg.Attributes.fill "rgba(0,0,0,0.85)"
                , Svg.Attributes.stroke strokeColor
                , Svg.Attributes.strokeWidth "7"
                ]
                []
            , -- Top teeth
              tooth "148,219 174,221 163,245"
            , tooth "232,216 257,219 247,243"
            , -- Bottom teeth
              tooth "110,271 136,275 127,251"
            , tooth "196,277 222,275 208,253"
            ]
        ]


strokedPolyline : String -> Svg msg
strokedPolyline points =
    Svg.polyline
        [ Svg.Attributes.points points
        , Svg.Attributes.fill "none"
        , Svg.Attributes.stroke strokeColor
        , Svg.Attributes.strokeWidth "7"
        , Svg.Attributes.strokeLinecap "round"
        , Svg.Attributes.strokeLinejoin "round"
        ]
        []


eye : Int -> Int -> Int -> Int -> Int -> Svg msg
eye cx cy rx ry rotation =
    Svg.ellipse
        [ Svg.Attributes.cx (String.fromInt cx)
        , Svg.Attributes.cy (String.fromInt cy)
        , Svg.Attributes.rx (String.fromInt rx)
        , Svg.Attributes.ry (String.fromInt ry)
        , Svg.Attributes.transform ("rotate(" ++ String.fromInt rotation ++ " " ++ String.fromInt cx ++ " " ++ String.fromInt cy ++ ")")
        , Svg.Attributes.fill "none"
        , Svg.Attributes.stroke strokeColor
        , Svg.Attributes.strokeWidth "7"
        ]
        []


tooth : String -> Svg msg
tooth points =
    Svg.polygon
        [ Svg.Attributes.points points
        , Svg.Attributes.fill strokeColor
        ]
        []


fileSvg : Html msg
fileSvg =
    Svg.svg
        [ Svg.Attributes.width "40"
        , Svg.Attributes.height "50"
        , Svg.Attributes.viewBox "0 0 40 50"
        ]
        [ Svg.polygon
            [ Svg.Attributes.points "4,4 26,4 36,14 36,46 4,46"
            , Svg.Attributes.fill "rgba(30,30,30,0.9)"
            , Svg.Attributes.stroke strokeColor
            , Svg.Attributes.strokeWidth "3"
            , Svg.Attributes.strokeLinejoin "round"
            ]
            []
        , strokedPolylineThin "26,4 26,14 36,14"
        , strokedPolylineThin "11,24 29,24"
        , strokedPolylineThin "11,32 29,32"
        , strokedPolylineThin "11,40 23,40"
        ]


strokedPolylineThin : String -> Svg msg
strokedPolylineThin points =
    Svg.polyline
        [ Svg.Attributes.points points
        , Svg.Attributes.fill "none"
        , Svg.Attributes.stroke strokeColor
        , Svg.Attributes.strokeWidth "3"
        , Svg.Attributes.strokeLinecap "round"
        ]
        []
