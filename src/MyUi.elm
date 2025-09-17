module MyUi exposing
    ( alertColor
    , background1
    , background2
    , background3
    , blockClickPropagation
    , border1
    , border2
    , buttonBackground
    , buttonBorder
    , buttonFontColor
    , cancelButtonBackground
    , colorToStyle
    , column
    , container
    , css
    , datestamp
    , datestampDate
    , deleteButton
    , deleteButtonBackground
    , deleteButtonFont
    , disabledButtonBackground
    , elButton
    , emailAddress
    , errorBox
    , errorColor
    , focusEffect
    , font1
    , font2
    , font3
    , gray
    , heightAttr
    , highlightedBorder
    , hover
    , hoverAndMentionColor
    , hoverAndReplyToColor
    , hoverHighlight
    , hoverText
    , htmlStyle
    , id
    , inputBackground
    , inputBorder
    , insetBottom
    , insetTop
    , isMobile
    , label
    , mentionColor
    , montserrat
    , noPointerEvents
    , noShrinking
    , prewrap
    , primaryButton
    , radioColumn
    , radioRowWithSeparators
    , replyToColor
    , rowButton
    , secondaryButton
    , secondaryGray
    , secondaryGrayBorder
    , simpleButton
    , textLinkColor
    , timeElapsedView
    , timestamp
    , userLabelHtml
    , white
    , widthAttr
    )

import Color
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Date exposing (Date)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import EmailAddress exposing (EmailAddress)
import Html exposing (Html)
import Html.Attributes
import Html.Events.Extra.Touch
import Icons
import Id exposing (Id, UserId)
import Json.Decode
import PersonName exposing (PersonName)
import Quantity
import Round
import SeqDict exposing (SeqDict)
import Time exposing (Month(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Shadow


rhythm : number
rhythm =
    8


spacing : Ui.Attribute msg
spacing =
    Ui.spacing rhythm


{-| Column with preapplied standard spacing.
-}
column : List (Ui.Attribute msg) -> List (Element msg) -> Element msg
column attrs children =
    Ui.column (spacing :: attrs) children


errorBox : HtmlId -> (String -> msg) -> String -> Element msg
errorBox htmlId onPress error =
    Ui.row
        [ Ui.border 1
        , Ui.borderColor errorColor
        , Ui.Font.color errorColor
        , Ui.rounded 2
        , errorBackground
        , Ui.spacing 8
        ]
        [ Ui.el
            [ Ui.clipWithEllipsis
            , hoverText error
            , Ui.paddingWith { left = 4, right = 0, top = 2, bottom = 2 }
            ]
            (Ui.text error)
        , rowButton
            htmlId
            (onPress error)
            [ Ui.width Ui.shrink
            , Ui.paddingWith { left = 0, right = 4, top = 2, bottom = 2 }
            ]
            [ Icons.copy, Ui.text "Copy" ]
        ]


label : HtmlId -> List (Ui.Attribute msg) -> Element msg -> { element : Element msg, id : Ui.Input.Label }
label htmlId attributes element =
    Ui.Input.label (Dom.idToString htmlId) attributes element


errorBackground : Ui.Attribute msg
errorBackground =
    Ui.background (Ui.rgb 255 240 240)


timeElapsedView : Time.Posix -> Time.Posix -> Element msg
timeElapsedView now event =
    Ui.el
        [ hoverText (datestamp now) ]
        (timeElapsed now event |> Ui.text)


datestamp : Time.Posix -> String
datestamp time =
    String.padLeft 2 '0' (String.fromInt (Time.toDay Time.utc time))
        ++ "/"
        ++ String.padLeft 2 '0' (String.fromInt (monthToInt (Time.toMonth Time.utc time)))
        ++ "/"
        ++ String.right 2 (String.fromInt (Time.toYear Time.utc time))


datestampDate : Date -> String
datestampDate date =
    (case Date.month date of
        Jan ->
            "January"

        Feb ->
            "February"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "November"

        Dec ->
            "December"
    )
        ++ " "
        ++ String.fromInt (Date.day date)
        ++ ", "
        ++ String.fromInt (Date.year date)


timestamp : Time.Posix -> Time.Zone -> String
timestamp time zone =
    String.padLeft 2 '0' (String.fromInt (Time.toHour zone time))
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute zone time))


monthToInt : Month -> Int
monthToInt month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


timeElapsed : Time.Posix -> Time.Posix -> String
timeElapsed now event =
    let
        difference : Duration
        difference =
            Duration.from event now |> Quantity.abs

        months =
            Duration.inDays difference / 30 |> floor

        suffix =
            if Time.posixToMillis now <= Time.posixToMillis event then
                ""

            else
                " ago"
    in
    if months >= 2 then
        String.fromInt months ++ "\u{00A0}months" ++ suffix

    else
        let
            weeks =
                Duration.inWeeks difference |> floor
        in
        if weeks >= 2 then
            String.fromInt weeks ++ "\u{00A0}weeks" ++ suffix

        else
            let
                days =
                    Duration.inDays difference |> round
            in
            if days > 1 then
                String.fromInt days ++ "\u{00A0}days" ++ suffix

            else
                let
                    hours =
                        Duration.inHours difference |> floor
                in
                if hours > 22 then
                    "1\u{00A0}day" ++ suffix

                else if hours > 6 then
                    String.fromInt hours ++ "\u{00A0}hours" ++ suffix

                else if Duration.inHours difference >= 1.2 then
                    removeTrailing0s 1 (Duration.inHours difference) ++ "\u{00A0}hours" ++ suffix

                else
                    let
                        minutes =
                            Duration.inMinutes difference |> round
                    in
                    if minutes > 1 then
                        String.fromInt minutes ++ "\u{00A0}minutes" ++ suffix

                    else
                        "1\u{00A0}minute" ++ suffix


removeTrailing0s : Int -> Float -> String
removeTrailing0s decimalPoints value =
    case Round.round decimalPoints value |> String.split "." of
        [ nonDecimal, decimal ] ->
            if decimalPoints > 0 then
                nonDecimal
                    ++ "."
                    ++ (String.foldr
                            (\char ( text, reachedNonZero ) ->
                                if reachedNonZero || char /= '0' then
                                    ( text, True )

                                else
                                    ( String.dropRight 1 text, False )
                            )
                            ( decimal, False )
                            decimal
                            |> Tuple.first
                       )
                    |> dropSuffix "."

            else
                nonDecimal

        [ nonDecimal ] ->
            nonDecimal

        _ ->
            "0"


dropSuffix : String -> String -> String
dropSuffix suffix string =
    if String.endsWith suffix string then
        String.dropRight (String.length suffix) string

    else
        string



-- Colors --


black : Ui.Color
black =
    Ui.rgb 0 0 0


white : Ui.Color
white =
    Ui.rgb 255 255 255


gray : Ui.Color
gray =
    Ui.rgb 100 100 100


green500 : Ui.Color
green500 =
    Ui.rgb 72 187 120


green500Border : Ui.Color
green500Border =
    Ui.rgb 55 141 91


secondaryGray : Ui.Color
secondaryGray =
    Ui.rgb 240 240 240


secondaryGrayBorder : Ui.Color
secondaryGrayBorder =
    Ui.rgb 215 215 215


unselectedGray : Ui.Color
unselectedGray =
    Ui.rgb 220 220 220


textLinkColor : Ui.Color
textLinkColor =
    Ui.rgb 66 93 203


emailAddress : EmailAddress -> Element msg
emailAddress emailAddress2 =
    Ui.el [ Ui.Font.bold ] (Ui.text (EmailAddress.toString emailAddress2))


radioColumn : HtmlId -> (option -> msg) -> Maybe option -> String -> List ( option, String ) -> Element msg
radioColumn htmlId onPress maybeValue title options =
    let
        label2 =
            Ui.Input.label (Dom.idToString htmlId) [ Ui.Font.bold ] (Ui.text title)
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ label2.element
        , Ui.Input.chooseOne
            Ui.column
            [ Ui.spacing 4 ]
            { onChange = onPress
            , options = List.map (\( value, text ) -> radioOption htmlId value text) options
            , selected = maybeValue
            , label = label2.id
            }
        ]


radioOption : HtmlId -> value -> String -> Ui.Input.Option value msg
radioOption htmlId value text =
    Ui.Input.optionWith
        value
        (\option ->
            Ui.row
                [ Ui.spacing 6, Ui.id (Dom.idToString htmlId ++ "_" ++ text) ]
                [ Ui.el
                    [ Ui.width (Ui.px 23)
                    , Ui.height (Ui.px 23)
                    , Ui.background (Ui.rgb 250 250 255)
                    , Ui.rounded 99
                    , Ui.border 2
                    , Ui.borderColor
                        (case option of
                            Ui.Input.Selected ->
                                background1

                            Ui.Input.Idle ->
                                background1

                            Ui.Input.Focused ->
                                white
                        )
                    ]
                    (case option of
                        Ui.Input.Selected ->
                            Ui.el
                                [ Ui.width (Ui.px 15)
                                , Ui.height (Ui.px 15)
                                , Ui.centerX
                                , Ui.centerY
                                , Ui.background background1
                                , Ui.rounded 99
                                ]
                                Ui.none

                        Ui.Input.Idle ->
                            Ui.none

                        Ui.Input.Focused ->
                            Ui.none
                    )
                , Ui.text text
                ]
        )


radioRowWithSeparators : List (Ui.Attribute msg) -> a -> (a -> msg) -> Element msg -> List (List ( a, String )) -> Element msg
radioRowWithSeparators attrs selected onPress separator children =
    let
        outerCount =
            List.length children
    in
    children
        |> List.indexedMap
            (\outerIndex innerChildren ->
                let
                    innerCount : Int
                    innerCount =
                        List.length innerChildren
                in
                List.indexedMap
                    (\innerIndex ( child, label2 ) ->
                        let
                            commonAttrs : List (Ui.Attribute msg)
                            commonAttrs =
                                [ Ui.Input.button (onPress child)
                                , touchPress (onPress child)
                                , Ui.attrIf (child /= selected) unselectedBackground
                                , Ui.attrIf (child /= selected) (Ui.Font.color black)
                                , Ui.width Ui.fill
                                , Ui.Shadow.shadows []
                                ]

                            borderAttrs : List (Ui.Attribute msg)
                            borderAttrs =
                                if innerCount == 1 && outerCount == 1 then
                                    [ Ui.rounded 8 ]

                                else if innerIndex == 0 && outerIndex == 0 then
                                    [ Ui.roundedWith { topLeft = 8, bottomRight = 0, bottomLeft = 8, topRight = 0 }
                                    ]

                                else if innerIndex == 0 && outerIndex > 0 then
                                    [ Ui.rounded 0
                                    , Ui.borderWith { left = 1, right = 1, top = 1, bottom = 1 }
                                    ]

                                else if innerIndex == innerCount - 1 && outerIndex == outerCount - 1 then
                                    [ Ui.roundedWith { topLeft = 0, bottomRight = 8, bottomLeft = 0, topRight = 8 }
                                    , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
                                    ]

                                else
                                    [ Ui.rounded 0
                                    , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
                                    ]
                        in
                        button (commonAttrs ++ borderAttrs) label2
                    )
                    innerChildren
                    |> Ui.row [ Ui.Shadow.shadows buttonShadows ]
            )
        |> List.intersperse separator
        |> Ui.row attrs


noPointerEvents : Ui.Attribute msg
noPointerEvents =
    htmlStyle "pointer-events" "none"



-- Buttons --


unselectedBackground : Ui.Attribute msg
unselectedBackground =
    Ui.background unselectedGray


button : List (Ui.Attribute msg) -> String -> Element msg
button attrs text =
    Ui.el
        ([ Ui.paddingXY 8 4
         , Ui.rounded 8
         , Ui.border 1
         , Ui.width Ui.shrink
         , Ui.background green500
         , Ui.borderColor green500Border
         , Ui.Font.weight 600
         , Ui.Font.color white
         , Ui.Shadow.shadows buttonShadows
         , Ui.contentCenterY
         ]
            ++ attrs
        )
        (Ui.text text)


elButton : HtmlId -> msg -> List (Ui.Attribute msg) -> Element msg -> Element msg
elButton htmlId onPress attributes content =
    Ui.el
        (Ui.id (Dom.idToString htmlId) :: Ui.Input.button onPress :: attributes)
        content


rowButton : HtmlId -> msg -> List (Ui.Attribute msg) -> List (Element msg) -> Element msg
rowButton htmlId onPress attributes content =
    Ui.row
        (Ui.id (Dom.idToString htmlId) :: Ui.Input.button onPress :: attributes)
        content


buttonShadows : List { color : Ui.Color, x : Float, y : Float, blur : Float, size : Float }
buttonShadows =
    [ { color = Ui.rgba 0 0 0 0.1, x = 0, y = 2, blur = 4, size = -1 }
    , { color = Ui.rgba 0 0 0 0.1, x = 0, y = 0, blur = 2, size = -2 }
    ]


hover : Bool -> List Ui.Anim.Animated -> Ui.Attribute msg
hover isMobile2 animated =
    if isMobile2 then
        Ui.noAttr

    else
        Ui.Anim.hovered (Ui.Anim.ms 10) animated


prewrap : Ui.Attribute msg
prewrap =
    htmlStyle "white-space" "pre-wrap"


container : Bool -> String -> List (Element msg) -> Element msg
container isMobile2 label2 contents =
    let
        paddingX =
            if isMobile2 then
                8

            else
                16
    in
    Ui.el
        [ Ui.paddingWith
            { left = paddingX
            , right = paddingX
            , top = 10
            , bottom = 0
            }
        , Ui.text label2
            |> Ui.el
                [ Ui.Font.bold
                , Ui.Font.size 14
                , Ui.move
                    { x = paddingX + 12
                    , y = 0
                    , z = 0
                    }
                , Ui.paddingXY 2 0
                , Ui.width Ui.shrink
                , Ui.background background1
                ]
            |> Ui.inFront
        ]
        (Ui.column
            [ Ui.border 1
            , Ui.rounded 4
            , Ui.padding 16
            , Ui.spacing 16
            ]
            contents
        )


primaryButton : HtmlId -> msg -> String -> Element msg
primaryButton htmlId onPress text =
    button
        [ Ui.Input.button onPress
        , id htmlId
        , focusEffect
        ]
        text


simpleButton : HtmlId -> msg -> Element msg -> Element msg
simpleButton htmlId onPress content =
    Ui.el
        [ Ui.Input.button onPress
        , Ui.borderColor buttonBorder
        , Ui.border 1
        , Ui.background buttonBackground
        , Ui.rounded 4
        , id htmlId
        , Ui.width Ui.shrink
        , Ui.paddingXY 16 8
        , focusEffect
        , Ui.Font.weight 500
        ]
        content


focusEffect : Ui.Attribute msg
focusEffect =
    Ui.Anim.focused (Ui.Anim.ms 10) [ Ui.Anim.borderColor white ]


touchPress : msg -> Ui.Attribute msg
touchPress onPress =
    Html.Events.Extra.Touch.onStart (\_ -> onPress) |> Ui.htmlAttribute


htmlStyle : String -> String -> Ui.Attribute msg
htmlStyle name value =
    Ui.htmlAttribute (Html.Attributes.style name value)


montserrat : Ui.Attribute msg
montserrat =
    Ui.Font.family [ Ui.Font.typeface "Montserrat", Ui.Font.typeface "Helvetica", Ui.Font.sansSerif ]


secondaryButton : HtmlId -> msg -> String -> Element msg
secondaryButton htmlId onPress label2 =
    Ui.el
        [ Ui.Input.button onPress
        , id htmlId
        , Ui.background secondaryGray
        , focusEffect
        , Ui.border 1
        , Ui.Font.color (Ui.rgb 0 0 0)
        , Ui.rounded 4
        , Ui.width Ui.shrink
        , Ui.paddingXY 16 8
        , Ui.Font.weight 500
        ]
        (Ui.text label2)


deleteButton : HtmlId -> msg -> Element msg
deleteButton htmlId onPress =
    Ui.el
        [ Ui.Input.button onPress
        , Dom.idToString htmlId |> Ui.id
        , hoverText "Delete"
        , Ui.padding 3
        , Ui.background (Ui.rgb 255 100 100)
        , Ui.Font.color white
        , Ui.rounded 4
        , Ui.width Ui.shrink
        , Ui.Shadow.shadows
            [ { x = 0, y = 1, size = 0, blur = 2, color = Ui.rgba 0 0 0 0.1 } ]
        ]
        (Ui.html Icons.delete)


hoverText : String -> Ui.Attribute msg
hoverText text =
    Ui.htmlAttribute (Html.Attributes.title text)


id : HtmlId -> Ui.Attribute msg
id htmlId =
    Ui.id (Dom.idToString htmlId)


css : Html msg
css =
    Html.node "style"
        []
        [ Html.text
            (fontFace 800 "Montserrat-ExtraBold"
                ++ fontFace 700 "Montserrat-Bold"
                ++ fontFace 600 "Montserrat-SemiBold"
                ++ fontFace 500 "Montserrat-Medium"
                ++ fontFace 400 "Montserrat-Regular"
                ++ fontFace 300 "Montserrat-Light"
                ++ """
textarea::selection {
    background-color: rgb(0,120,215);
    color: rgba(0,0,0,0);
}
textarea::-moz-selection {
    background-color: rgb(0,120,215);
    color: rgba(0,0,0,0);
}

//https://stackoverflow.com/a/54410301
.disable-scrollbars::-webkit-scrollbar {
  background: transparent;
  width: 0px;
}
.disable-scrollbars {
  scrollbar-width: none;
  -ms-overflow-style: none;
}

a:link {
  color: rgb(176,193,255);
  text-decoration: none;
}
a:hover {
  color: rgb(176,193,255);
  text-decoration: underline;
}
a:visited {
  color: rgb(206,193,225);
}
html, body {
  overscroll-behavior: none;
}
body {
  overflow: hidden;
  height:100vh !important;
  background-color:rgb(50,60,90);
}
"""
            )
        ]


fontFace : Int -> String -> String
fontFace weight name =
    """
@font-face {
  font-family: 'Montserrat';
  font-style: normal;
  font-weight: """ ++ String.fromInt weight ++ """;
  font-stretch: normal;
  font-display: swap;
  src: url(/fonts/""" ++ name ++ """.ttf) format('truetype');
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD, U+2192, U+2713;
}"""


widthAttr : Int -> Html.Attribute msg
widthAttr width =
    Html.Attributes.style "width" (String.fromInt width ++ "px")


heightAttr : Int -> Html.Attribute msg
heightAttr height =
    Html.Attributes.style "height" (String.fromInt height ++ "px")


userLabelHtml : Id UserId -> SeqDict (Id UserId) { a | name : PersonName } -> Html msg
userLabelHtml userId allUsers =
    case SeqDict.get userId allUsers of
        Just user ->
            userLabel2Html user

        Nothing ->
            Html.span
                [ Html.Attributes.style "background-color" "rgb(50,70,240)"
                , Html.Attributes.style "padding" "1px 1px 0 1px"
                , Html.Attributes.style "color" "rgb(215,235,255)"
                , Html.Attributes.style "border-radius" "2px"
                , Html.Attributes.style "white-space" "nowrap"
                ]
                [ Html.text "@<name missing>" ]


userLabel2Html : { a | name : PersonName } -> Html msg
userLabel2Html user =
    Html.span
        [ Html.Attributes.style "background-color" "rgb(50,70,240)"
        , Html.Attributes.style "padding" "1px 1px 0 1px"
        , Html.Attributes.style "color" "rgb(215,235,255)"
        , Html.Attributes.style "border-radius" "2px"
        , Html.Attributes.style "white-space" "nowrap"
        ]
        [ Html.text ("@" ++ PersonName.toString user.name) ]


blockClickPropagation : msg -> Ui.Attribute msg
blockClickPropagation msg =
    Ui.Events.stopPropagationOn "click" (Json.Decode.succeed ( msg, True ))


insetTop : String
insetTop =
    --"40px"
    "env(safe-area-inset-top)"


insetBottom : String
insetBottom =
    --"40px"
    "env(safe-area-inset-bottom)"


isMobile : { a | windowSize : Coord CssPixels } -> Bool
isMobile model =
    Coord.xRaw model.windowSize < 700


noShrinking : Ui.Attribute msg
noShrinking =
    htmlStyle "flex-shrink" "0"


colorToStyle : Ui.Color -> String
colorToStyle color =
    let
        { red, green, blue, alpha } =
            Color.toRgba color

        floatToInt value =
            round (value * 255) |> String.fromInt
    in
    "rgba("
        ++ floatToInt red
        ++ ","
        ++ floatToInt green
        ++ ","
        ++ floatToInt blue
        ++ ","
        ++ String.fromFloat alpha
        ++ ")"


background1 : Ui.Color
background1 =
    Ui.rgb 14 20 40


background2 : Ui.Color
background2 =
    Ui.rgb 32 40 70


background3 : Ui.Color
background3 =
    Ui.rgb 50 60 90


inputBackground : Ui.Color
inputBackground =
    Ui.rgb 35 42 70


inputBorder : Ui.Color
inputBorder =
    Ui.rgb 97 104 124


buttonBackground : Ui.Color
buttonBackground =
    Ui.rgb 64 122 178


disabledButtonBackground : Ui.Color
disabledButtonBackground =
    Ui.rgb 130 133 135


cancelButtonBackground : Ui.Color
cancelButtonBackground =
    Ui.rgb 196 200 204


deleteButtonBackground : Ui.Color
deleteButtonBackground =
    Ui.rgb 180 50 40


deleteButtonFont : Ui.Color
deleteButtonFont =
    Ui.rgb 255 240 250


buttonBorder : Ui.Color
buttonBorder =
    Ui.rgb 10 20 30


buttonFontColor : Ui.Color
buttonFontColor =
    Ui.rgb 0 0 0


font1 : Ui.Color
font1 =
    Ui.rgb 255 255 255


font2 : Ui.Color
font2 =
    Ui.rgb 220 220 220


font3 : Ui.Color
font3 =
    Ui.rgb 160 180 200


border1 : Ui.Color
border1 =
    Ui.rgb 60 70 100


border2 : Ui.Color
border2 =
    Ui.rgb 34 39 56


highlightedBorder : Ui.Color
highlightedBorder =
    Ui.rgb 12 140 200


errorColor : Ui.Color
errorColor =
    Ui.rgb 240 170 180


hoverHighlight : Ui.Color
hoverHighlight =
    Ui.rgba 255 255 255 0.1


replyToColor : Ui.Color
replyToColor =
    Ui.rgb 69 69 140


mentionColor : Ui.Color
mentionColor =
    Ui.rgb 130 110 100


hoverAndReplyToColor : Ui.Color
hoverAndReplyToColor =
    Ui.rgb 84 84 161


hoverAndMentionColor : Ui.Color
hoverAndMentionColor =
    Ui.rgb 156 132 130


alertColor : Ui.Color
alertColor =
    Ui.rgb 255 10 40
