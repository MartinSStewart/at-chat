module MyUi exposing
    ( Copied(..)
    , LastCopy
    , alertColor
    , allMonths
    , background1
    , background2
    , background3
    , black
    , blockClickPropagation
    , border1
    , border2
    , bounceScroll
    , buttonBackground
    , buttonBorder
    , canScroll
    , channelAndGuildColumnWidth
    , channelHeaderHeight
    , colorToHex
    , colorToStyle
    , colorWithAlpha
    , column
    , container
    , conversationWidthIgnoreScrollbar
    , copyBox
    , css
    , dangerRed
    , datestamp
    , datestampDate
    , datestampNoLineBreaks
    , deleteButton
    , deleteButtonBackground
    , deleteButtonBorder
    , deleteButtonFont
    , details
    , dimFont
    , disabledButtonBackground
    , disabledButtonBorder
    , elButton
    , emailAddress
    , errorBox
    , errorColor
    , fadeIn
    , font1
    , font2
    , font3
    , guildIconFullWidth
    , heightAttr
    , highlightedBorder
    , hover
    , hoverAndMentionColor
    , hoverAndReplyToColor
    , hoverHighlight
    , hoverText
    , htmlStyle
    , id
    , imagePlaceholderStyle
    , inputBackground
    , inputBorder
    , insetBottom
    , insetTop
    , isMobile
    , isMobileAlt
    , label
    , lazyLoading
    , memberColumnWidth
    , mentionColor
    , monospace
    , monthToInt
    , monthToString
    , newPasswordCopyBox
    , noPointerEvents
    , noShrinking
    , notoSans
    , outwardBottomCorner
    , prewrap
    , radioCircle
    , radioColumn
    , radioOption
    , radioRow
    , radioRowWithSeparators
    , replyToColor
    , rowButton
    , scrim
    , scrollable
    , secondaryButton
    , secondaryButtonTall
    , secondaryGray
    , secondaryGrayBorder
    , selectedHighlight
    , selectedTextBackground
    , simpleButton
    , tabBackground
    , tabSideEdge
    , textLinkColor
    , textLinkColorOnDarkBackground
    , timeElapsed
    , timeElapsedShort
    , timeElapsedView
    , timestamp
    , touchPress
    , userLabelBackground
    , userLabelFontColor
    , userLabelHtml
    , warningHeader
    , weakHoverHighlight
    , white
    , widthAttr
    )

import Color exposing (Color)
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
import Json.Decode
import PersonName exposing (PersonName)
import Quantity
import Round
import SeqDict exposing (SeqDict)
import Svg
import Svg.Attributes
import Time exposing (Month(..))
import Touch exposing (Drag(..))
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
        , elButton
            htmlId
            (onPress error)
            [ Ui.width Ui.shrink
            , Ui.paddingWith { left = 4, right = 4, top = 2, bottom = 2 }
            , Ui.Font.bold
            , Ui.borderWith { left = 1, right = 0, top = 0, bottom = 0 }
            , Ui.spacing 4
            ]
            (Ui.html Icons.copy)
        ]


type alias LastCopy =
    { copiedAt : Time.Posix, copied : Copied }


type Copied
    = CopiedText String
    | CopiedImage String


copyBox : HtmlId -> Maybe String -> (String -> msg) -> msg -> { a | lastCopied : Maybe LastCopy } -> String -> Element msg
copyBox htmlId label2 pressedCopyText noOp loaded text =
    let
        label4 =
            case label2 of
                Just label3 ->
                    Ui.Input.label
                        (Dom.idToString htmlId ++ "_textInput")
                        [ Ui.Font.size 14, Ui.Font.color font3, Ui.Font.bold ]
                        (Ui.text label3)

                Nothing ->
                    { element = Ui.none, id = Ui.Input.labelHidden (Dom.idToString htmlId ++ "_textInput") }
    in
    Ui.column
        [ Ui.spacing 2 ]
        [ label4.element
        , Ui.row
            []
            [ Ui.Input.text
                [ Ui.clipWithEllipsis
                , Ui.paddingWith { left = 8, right = 0, top = 2, bottom = 2 }
                , Ui.htmlAttribute (Html.Attributes.readonly True)
                , Ui.background (Ui.rgba 0 0 0 0.2)
                , Ui.border 1
                , Ui.borderColor inputBorder
                , Ui.roundedWith { topLeft = 4, topRight = 0, bottomLeft = 4, bottomRight = 0 }
                , Ui.height Ui.fill
                ]
                { onChange = \_ -> noOp
                , text = text
                , placeholder = Nothing
                , label = label4.id
                }
            , elButton
                (Dom.id (Dom.idToString htmlId ++ "_copy"))
                (pressedCopyText text)
                [ Ui.width Ui.shrink
                , Ui.paddingWith { left = 8, right = 8, top = 2, bottom = 2 }
                , Ui.borderColor inputBorder
                , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
                , Ui.roundedWith { topLeft = 0, topRight = 4, bottomLeft = 0, bottomRight = 4 }
                , Ui.spacing 4
                , Ui.background buttonBackground
                , Ui.height (Ui.px 40)
                , Ui.contentCenterY
                ]
                (case loaded.lastCopied of
                    Just copied ->
                        if copied.copied == CopiedText text then
                            Ui.text "Copied!"

                        else
                            Ui.html Icons.copy

                    Nothing ->
                        Ui.html Icons.copy
                )
            ]
        ]


{-| `copyBox` for a secret that has only just been made.

The field is a password input rather than a plain one so that a password manager notices
it and offers to save it. That offer is worth a lot here, because saving the value
somewhere is the whole job the box exists for: nothing in the page and nothing on the
server keeps a copy.

It stays masked for the same reason a password manager masks a password it just made. The
copy button is how the value gets out, so there is nothing to read it for, and a secret
shown in full at the exact moment it is worth the most is a poor thing to have on screen.

-}
newPasswordCopyBox : HtmlId -> String -> (String -> msg) -> msg -> { a | lastCopied : Maybe LastCopy } -> String -> Element msg
newPasswordCopyBox htmlId label2 pressedCopyText noOp loaded text =
    let
        label3 : { element : Element msg, id : Ui.Input.Label }
        label3 =
            Ui.Input.label
                (Dom.idToString htmlId ++ "_textInput")
                [ Ui.Font.size 14, Ui.Font.color font3, Ui.Font.bold ]
                (Ui.text label2)
    in
    Ui.column
        [ Ui.spacing 2 ]
        [ label3.element
        , Ui.row
            []
            [ Ui.Input.newPassword
                [ Ui.clipWithEllipsis
                , Ui.paddingWith { left = 8, right = 0, top = 2, bottom = 2 }
                , Ui.htmlAttribute (Html.Attributes.readonly True)
                , Ui.background (Ui.rgba 0 0 0 0.2)
                , Ui.border 1
                , Ui.borderColor inputBorder
                , Ui.roundedWith { topLeft = 4, topRight = 0, bottomLeft = 4, bottomRight = 0 }
                , Ui.height Ui.fill
                ]
                { onChange = \_ -> noOp
                , text = text
                , placeholder = Nothing
                , label = label3.id
                , show = False
                }
            , elButton
                (Dom.id (Dom.idToString htmlId ++ "_copy"))
                (pressedCopyText text)
                [ Ui.width Ui.shrink
                , Ui.paddingWith { left = 8, right = 8, top = 2, bottom = 2 }
                , Ui.borderColor inputBorder
                , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
                , Ui.roundedWith { topLeft = 0, topRight = 4, bottomLeft = 0, bottomRight = 4 }
                , Ui.spacing 4
                , Ui.background buttonBackground
                , Ui.height (Ui.px 40)
                , Ui.contentCenterY
                ]
                (case loaded.lastCopied of
                    Just copied ->
                        if copied.copied == CopiedText text then
                            Ui.text "Copied!"

                        else
                            Ui.html Icons.copy

                    Nothing ->
                        Ui.html Icons.copy
                )
            ]
        ]


label : HtmlId -> List (Ui.Attribute msg) -> Element msg -> { element : Element msg, id : Ui.Input.Label }
label htmlId attributes element =
    Ui.Input.label (Dom.idToString htmlId) attributes element


errorBackground : Ui.Attribute msg
errorBackground =
    Ui.background (Ui.rgb 38 10 22)


timeElapsedView : Time.Zone -> Time.Posix -> Time.Posix -> Element msg
timeElapsedView timezone now event =
    Ui.el
        [ hoverText (datestamp timezone now) ]
        (timeElapsed now event |> Ui.text)


datestamp : Time.Zone -> Time.Posix -> String
datestamp timezone time =
    monthToString (Time.toMonth timezone time)
        ++ " "
        ++ String.fromInt (Time.toDay timezone time)
        ++ ", "
        ++ String.fromInt (Time.toYear timezone time)


datestampNoLineBreaks : Time.Zone -> Time.Posix -> String
datestampNoLineBreaks timezone time =
    monthToString (Time.toMonth timezone time)
        ++ "\u{00A0}"
        ++ String.fromInt (Time.toDay timezone time)
        ++ ",\u{00A0}"
        ++ String.fromInt (Time.toYear timezone time)


allMonths : List Month
allMonths =
    [ Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec ]


monthToString : Month -> String
monthToString month =
    case month of
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


datestampDate : Date -> String
datestampDate date =
    monthToString (Date.month date)
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


timeElapsedShort : Time.Posix -> Time.Posix -> String
timeElapsedShort now event =
    let
        difference : Duration
        difference =
            Duration.from event now |> Quantity.abs

        years =
            Duration.inDays difference / 365 |> floor
    in
    if years >= 1 then
        String.fromInt years ++ "y"

    else
        let
            days =
                Duration.inDays difference |> round
        in
        if days > 1 then
            String.fromInt days ++ "d"

        else
            let
                hours =
                    Duration.inHours difference |> floor
            in
            if hours > 6 then
                String.fromInt hours ++ "h"

            else if Duration.inHours difference >= 1.5 then
                removeTrailing0s 1 (Duration.inHours difference) ++ "h"

            else
                let
                    minutes =
                        Duration.inMinutes difference |> round
                in
                String.fromInt minutes ++ "m"


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


textLinkColorOnDarkBackground : Ui.Color
textLinkColorOnDarkBackground =
    Ui.rgb 176 193 255


emailAddress : EmailAddress -> Element msg
emailAddress emailAddress2 =
    Ui.el [ Ui.Font.bold ] (Ui.text (EmailAddress.toString emailAddress2))


radioColumn : HtmlId -> (option -> msg) -> Maybe option -> Element msg -> List ( option, String ) -> Element msg
radioColumn htmlId onPress maybeValue title options =
    let
        label2 =
            Ui.Input.label (Dom.idToString htmlId) [ Ui.Font.bold ] title
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


radioRow : HtmlId -> (option -> msg) -> Maybe option -> String -> List ( option, String ) -> Element msg
radioRow htmlId onPress maybeValue title options =
    let
        label2 =
            Ui.Input.label (Dom.idToString htmlId) [ Ui.Font.bold ] (Ui.text title)
    in
    Ui.column
        [ Ui.spacing 8 ]
        [ label2.element
        , Ui.Input.chooseOne
            Ui.row
            [ Ui.spacing 24, Ui.wrap ]
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
                [ radioCircle option
                , Ui.text text
                ]
        )


radioFillColor : Ui.Color
radioFillColor =
    white


radioCircle : Ui.Input.OptionState -> Element msg
radioCircle option =
    Ui.el
        [ Ui.width (Ui.px 23)
        , Ui.height (Ui.px 23)
        , Ui.rounded 99
        , Ui.border 2
        , Ui.borderColor
            (case option of
                Ui.Input.Selected ->
                    radioFillColor

                Ui.Input.Idle ->
                    radioFillColor

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
                    , Ui.background radioFillColor
                    , Ui.rounded 99
                    , Ui.el
                        [ Ui.width (Ui.px 3)
                        , Ui.height (Ui.px 3)
                        , Ui.background background1
                        , Ui.rounded 99
                        , Ui.centerX
                        , Ui.centerY
                        ]
                        Ui.none
                        |> Ui.inFront
                    ]
                    Ui.none

            Ui.Input.Idle ->
                Ui.none

            Ui.Input.Focused ->
                Ui.none
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


{-| Slides whatever it's on into place, once. Elm only builds an element the first time it
appears, so this animates what has just turned up and leaves everything already on screen
where it is.
-}
fadeIn : Ui.Attribute msg
fadeIn =
    Ui.htmlAttribute (Html.Attributes.class "fade-in")


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
         , Ui.background buttonBackground
         , Ui.borderColor buttonBorder
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


container : Int -> Bool -> HtmlId -> msg -> Ui.Color -> Bool -> String -> List (Element msg) -> Element msg
container topPadding isExpanded htmlId onPressedExpand backgroundColor isMobile2 label2 contents =
    if isExpanded then
        Ui.el
            [ Ui.paddingWith
                { left = 16
                , right =
                    if isMobile2 then
                        8

                    else
                        16
                , top = topPadding
                , bottom = 0
                }
            , Ui.row
                [ Ui.Font.bold
                , Ui.Font.size 16
                , Ui.spacing 8
                , Ui.paddingXY 5 0
                , Ui.width Ui.shrink
                , Ui.background backgroundColor
                , Ui.Input.button onPressedExpand
                , Ui.id (Dom.idToString htmlId)
                ]
                [ Icons.collapseContainer
                , Ui.text label2
                ]
                |> Ui.inFront
            ]
            (Ui.column
                [ Ui.border 1
                , Ui.rounded 4
                , Ui.paddingWith
                    { left = 0
                    , right = 0
                    , top = 16
                    , bottom =
                        if isMobile2 then
                            8

                        else
                            16
                    }
                , Ui.spacing 16
                ]
                contents
            )

    else
        Ui.row
            [ Ui.Font.bold
            , Ui.Font.size 16
            , Ui.spacing 8
            , Ui.paddingXY 5 0
            , Ui.width Ui.shrink
            , Ui.background backgroundColor
            , Ui.Input.button onPressedExpand
            , Ui.id (Dom.idToString htmlId)
            ]
            [ Icons.expandContainer
            , Ui.text label2
            ]


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
        , Ui.Font.weight 500
        ]
        content


warningHeader : String -> Element msg
warningHeader text =
    Ui.row
        [ Ui.spacing 8, Ui.Font.bold, Ui.Font.color font3 ]
        [ Ui.html (Icons.warning 24), Ui.text text ]


touchPress : msg -> Ui.Attribute msg
touchPress onPress =
    Html.Events.Extra.Touch.onStart (\_ -> onPress) |> Ui.htmlAttribute


{-| A section that starts collapsed and opens when the summary is clicked. The
browser keeps track of whether it's open, so there's nothing to keep in the
model.

A `summary` only counts as the thing that opens a `details` while it's a direct
child of it, and elm-ui has no way to write two children of a node, so this is
written as plain html. That means `contents` has to be handed back to elm-ui,
which starts a fresh layout that doesn't inherit anything, so the font the rest
of the page is drawn with is set again here.

-}
details : String -> Element msg -> Element msg
details summaryText contents =
    Html.details
        []
        [ Html.summary
            [ Html.Attributes.style "cursor" "pointer"
            , Html.Attributes.style "font-weight" "bold"
            ]
            [ Html.text summaryText ]
        , Ui.embed [ notoSans, Ui.Font.size 16, Ui.Font.color font1 ] contents
        ]
        |> Ui.html


htmlStyle : String -> String -> Ui.Attribute msg
htmlStyle name value =
    Ui.htmlAttribute (Html.Attributes.style name value)


notoSans : Ui.Attribute msg
notoSans =
    Ui.Font.family [ Ui.Font.typeface "Noto Sans", Ui.Font.sansSerif ]


monospace : Ui.Attribute msg
monospace =
    Ui.Font.family [ Ui.Font.typeface "DejaVu Sans Mono", Ui.Font.monospace ]


secondaryButton : HtmlId -> msg -> String -> Element msg
secondaryButton htmlId onPress label2 =
    Ui.el
        [ Ui.Input.button onPress
        , id htmlId
        , Ui.background secondaryGray
        , Ui.border 1
        , Ui.Font.color black
        , Ui.rounded 4
        , Ui.width Ui.shrink
        , Ui.paddingXY 16 4
        , Ui.Font.weight 500
        ]
        (Ui.text label2)


secondaryButtonTall : HtmlId -> msg -> String -> Element msg
secondaryButtonTall htmlId onPress label2 =
    Ui.el
        [ Ui.Input.button onPress
        , id htmlId
        , Ui.background secondaryGray
        , Ui.border 1
        , Ui.Font.color black
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
        , Ui.width (Ui.px 40)
        , Ui.height (Ui.px 40)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.background deleteButtonBackground
        , Ui.border 1
        , Ui.borderColor deleteButtonBorder
        , Ui.Font.color deleteButtonFont
        , Ui.rounded 4
        , Ui.Shadow.shadows
            [ { x = 0, y = 1, size = 0, blur = 2, color = Ui.rgba 0 0 0 0.1 } ]
        ]
        (Ui.html Icons.delete)


hoverText : String -> Ui.Attribute msg
hoverText text =
    Ui.htmlAttribute (Html.Attributes.title text)


{-| The whole left or right edge of a selected tab, painted just outside the tab's
clickable area: the rounded top corner, the straight side below it and the corner at
the bottom that curves outward into the tab body. The tab itself only paints the flat
middle, so its clickable width can match the plain buttons sitting next to it while
the painted tab stays a rounded rectangle whose flat top spans exactly that width.
-}
tabSideEdge : Int -> Int -> Bool -> Ui.Color -> Ui.Attribute msg
tabSideEdge radius tabHeight isLeft color =
    let
        edgeWidth : Int
        edgeWidth =
            radius * 2

        edgeHeight : Int
        edgeHeight =
            tabHeight

        r : String
        r =
            String.fromInt radius

        w : String
        w =
            String.fromInt edgeWidth

        h : String
        h =
            String.fromInt edgeHeight

        arc : String
        arc =
            "A " ++ r ++ " " ++ r ++ " 0 0 "

        path : String
        path =
            if isLeft then
                String.join " "
                    [ "M " ++ w ++ ",0"
                    , "L " ++ String.fromInt (radius * 2) ++ ",0"
                    , arc ++ "0 " ++ r ++ "," ++ r
                    , "L " ++ r ++ "," ++ String.fromInt (edgeHeight - radius)
                    , arc ++ "1 0," ++ h
                    , "L " ++ w ++ "," ++ h
                    , "Z"
                    ]

            else
                String.join " "
                    [ "M 0,0"
                    , arc ++ "1 " ++ String.fromInt radius ++ "," ++ r
                    , "L " ++ String.fromInt radius ++ "," ++ String.fromInt (edgeHeight - radius)
                    , arc ++ "0 " ++ w ++ "," ++ h
                    , "L 0," ++ h
                    , "Z"
                    ]

        translate : String
        translate =
            (if isLeft then
                "translate(-" ++ String.fromFloat (toFloat radius * 1.5) ++ "px, "

             else
                "translate(" ++ String.fromFloat (toFloat radius * 1.5) ++ "px, "
            )
                ++ "0)"
    in
    Ui.inFront
        (Ui.el
            [ Ui.alignBottom
            , if isLeft then
                Ui.alignLeft

              else
                Ui.alignRight
            , Ui.width (Ui.px edgeWidth)
            , Ui.height (Ui.px edgeHeight)
            , Ui.Font.color color
            , htmlStyle "transform" translate
            , htmlStyle "pointer-events" "none"
            ]
            (Svg.svg
                [ Svg.Attributes.width w
                , Svg.Attributes.height h
                , Svg.Attributes.viewBox ("0 0 " ++ w ++ " " ++ h)
                , Svg.Attributes.style "display:block"
                ]
                [ Svg.path
                    [ Svg.Attributes.d path
                    , Svg.Attributes.fill "currentColor"
                    ]
                    []
                ]
                |> Ui.html
            )
        )


outwardBottomCorner : Int -> Bool -> Ui.Color -> Ui.Attribute msg
outwardBottomCorner radius isLeft color =
    let
        overlap : Int
        overlap =
            1

        r : String
        r =
            String.fromInt radius

        w : String
        w =
            String.fromInt (radius + overlap)

        path : String
        path =
            if isLeft then
                "M " ++ w ++ ",0 L " ++ r ++ ",0 A " ++ r ++ " " ++ r ++ " 0 0 1 0," ++ r ++ " L " ++ w ++ "," ++ r ++ " Z"

            else
                "M 0,0 L " ++ String.fromInt overlap ++ ",0 A " ++ r ++ " " ++ r ++ " 0 0 0 " ++ w ++ "," ++ r ++ " L 0," ++ r ++ " Z"

        translate : String
        translate =
            if isLeft then
                "translate(-" ++ r ++ "px, 0)"

            else
                "translate(" ++ r ++ "px, 0)"
    in
    Ui.inFront
        (Ui.el
            [ Ui.alignBottom
            , if isLeft then
                Ui.alignLeft

              else
                Ui.alignRight
            , Ui.move { x = 0, y = 1, z = 0 }
            , Ui.width (Ui.px (radius + overlap))
            , Ui.height (Ui.px radius)
            , Ui.Font.color color
            , htmlStyle "transform" translate
            , htmlStyle "pointer-events" "none"
            ]
            (Svg.svg
                [ Svg.Attributes.width w
                , Svg.Attributes.height r
                , Svg.Attributes.viewBox ("0 0 " ++ w ++ " " ++ r)
                , Svg.Attributes.style "display:block"
                ]
                [ Svg.path
                    [ Svg.Attributes.d path
                    , Svg.Attributes.fill "currentColor"
                    ]
                    []
                ]
                |> Ui.html
            )
        )


id : HtmlId -> Ui.Attribute msg
id htmlId =
    Ui.id (Dom.idToString htmlId)


css : Html msg
css =
    Html.node "style"
        []
        [ Html.text
            (notoSansFontFaces
                ++ dejavuSansMonoFontFaces
                ++ """
@font-face {
    font-family: "myemoji";
    src: local('Apple Color Emoji'), local('Android Emoji'), local('Segoe UI Emoji'), local('Noto Color Emoji'), local(EmojiSymbols), local(Symbola);
    unicode-range: U+231A-231B, U+23E9-23EC, U+23F0, U+23F3, U+25FD-25FE, U+2614-2615, U+2648-2653, U+267F, U+2693, U+26A1, U+26AA-26AB, U+26BD-26BE, U+26C4-26C5, U+26CE, U+26D4, U+26EA, U+26F2-26F3, U+26F5, U+26FA, U+26FD, U+2705, U+270A-270B, U+2728, U+274C, U+274E, U+2753-2755, U+2757, U+2795-2797, U+27B0, U+27BF, U+2B1B-2B1C, U+2B50, U+2B55, U+FE0F, U+1F004, U+1F0CF, U+1F18E, U+1F191-1F19A, U+1F1E6-1F1FF, U+1F201, U+1F21A, U+1F22F, U+1F232-1F236, U+1F238-1F23A, U+1F250-1F251, U+1F300-1F320, U+1F32D-1F335, U+1F337-1F393, U+1F3A0-1F3CA, U+1F3CF-1F3D3, U+1F3E0-1F3F0, U+1F3F4, U+1F3F8-1F43E, U+1F440, U+1F442-1F4FC, U+1F4FF-1F53D, U+1F54B-1F567, U+1F57A, U+1F595-1F596, U+1F5A4, U+1F5FB-1F64F, U+1F680-1F6CC, U+1F6D0-1F6D2, U+1F6D5-1F6D7, U+1F6DC-1F6DF, U+1F6EB-1F6EC, U+1F6F4-1F6FC, U+1F7E0-1F7EB, U+1F7F0, U+1F90C-1F93A, U+1F93C-1F945, U+1F947-1FA7C, U+1FA80-1FAC5, U+1FACE-1FADB, U+1FAE0-1FAE8, U+1FAF0-1FAF8;
    size-adjust: 130%;
}
textarea::selection {
    background-color: """
                ++ colorToStyle selectedTextBackground
                ++ """;
    color: rgba(0,0,0,0);
}
textarea::-moz-selection {
    background-color: """
                ++ colorToStyle selectedTextBackground
                ++ """;
    color: rgba(0,0,0,0);
}
/* The message input's textarea is drawn on top of the rich text so that the caret stays visible.
   Only the caret should be visible though, so its text and selection highlight are transparent and
   RichText.textWithSelection draws the highlight on the rich text instead. */
.rich-text-input::selection {
    background-color: transparent;
    color: transparent;
}
.rich-text-input::-moz-selection {
    background-color: transparent;
    color: transparent;
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
  scrollbar-color: """
                ++ colorToStyle font1
                ++ """ transparent
}
/* elm-ui hides the native focus ring with `.s:focus { outline: none; }` for
   every element it renders. This puts it back, but only for focus the browser
   considers worth showing (keyboard navigation, not mouse clicks). The
   .elm-ui-root prefix is there to outrank elm-ui's rule no matter which
   stylesheet the browser sees first. The offset is negative so that the
   outline is drawn inside the element and doesn't get clipped by scrollable
   or clipping parents. */
.elm-ui-root .s:focus-visible {
  outline: rgb(96,165,250) solid 2px;
  outline-offset: -2px;
}
.drawing-anchor-select {
  cursor: pointer;
  outline: rgba(0,0,0,0) solid 2px;
}
.drawing-anchor-select:hover {
  outline-color: rgb(96,165,250);
  background-color: rgba(96,165,250,0.3);
}
/* Hovering an .emoji-popup-container fades in the .emoji-popup inside it after a
   short delay. Used by the reaction emoji popup and by the custom emoji tooltip.
   The popup is display:none rather than merely transparent because an absolutely
   positioned box still counts towards the scrollable overflow of the conversation
   view even at opacity 0. A popup is much wider than the emoji it hangs off, so a
   message with custom emojis in it gave the conversation a horizontal scrollbar
   for popups nobody could see. */
.emoji-popup,
.custom-emoji-popup-arrow {
  display: none;
  opacity: 0;
}
.emoji-popup-container:hover .emoji-popup {
  display: flex;
  animation: emoji-popup-fade-in 0.2s ease 0.5s forwards;
}
.emoji-popup-container:hover .custom-emoji-popup-arrow {
  display: block;
  animation: emoji-popup-fade-in 0.2s ease 0.5s forwards;
}
@keyframes emoji-popup-fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}
/* Icons in the menu that hovering a message brings up are sized by the box they're given
   rather than by whatever the svg says, since browsers don't agree on how to size an svg
   that leaves one of its dimensions to them. */
.mini-button-icon {
  width: 24px;
  height: 24px;
}
.mini-button-icon > svg {
  width: 100%;
  height: 100%;
  display: block;
}
/* A section of a sheep game's results turning up. It waits a moment before sliding into
   place, so that the room has a chance to look up before the answer appears. */
.fade-in {
  animation: fade-in 2s;
}
@keyframes fade-in {
  0% { opacity: 0; transform: translate(0px, -20px); }
  50% { opacity: 0; transform: translate(0px, -20px); }
  100% { opacity: 1; }
}
/* The custom emoji tooltip hangs above its emoji, centred on it. The arrow is a
   sibling of the tooltip rather than a child of it so that it keeps pointing at
   the emoji when the tooltip below slides sideways. */
.custom-emoji-popup {
  position: absolute;
  bottom: calc(100% + 8px);
  left: 50%;
  transform: translateX(-50%);
}
.custom-emoji-popup-arrow {
  position: absolute;
  bottom: calc(100% + 1px);
  left: calc(50% - 8px);
  width: 0;
  height: 0;
}
/* Centred is fine until the emoji is near the edge of the window, where half a
   tooltip hangs off the side of the conversation and gives it a horizontal
   scrollbar. Browsers with anchor positioning slide the tooltip back on screen
   instead of overflowing: position-area centres it on the emoji, and the
   fallbacks line its right edge up with the emoji at the right of the screen, or
   its left edge at the left. position: fixed is what takes it out of the
   conversation's scrollable area, so nothing it does can scroll the conversation.
   Browsers without anchor positioning keep the centred rules above. */
@supports (anchor-scope: --a) and (position-area: top span-all) {
  .emoji-popup-container {
    anchor-name: --custom-emoji;
    /* Without a scope, every tooltip on the page anchors itself to the last emoji
       in the document rather than to the emoji it belongs to */
    anchor-scope: --custom-emoji;
  }
  .custom-emoji-popup {
    position: fixed;
    position-anchor: --custom-emoji;
    position-area: top span-all;
    justify-self: anchor-center;
    position-try-fallbacks: top span-left, top span-right;
    /* A fixed tooltip is no longer clipped by the conversation, so it has to hide
       itself when its emoji scrolls out of view */
    position-visibility: anchors-visible;
    inset: auto;
    transform: none;
    margin-bottom: 8px;
  }
}
"""
            )
        ]


{-| Noto Sans is used for all normal text so that text placement is consistent
across operating systems instead of relying on whatever default sans-serif font
the browser picks. The latin and latin-ext subsets are loaded for each weight the
app uses (400/500/600/700). Any glyph outside those ranges falls back to the
system sans-serif font.
-}
notoSansFontFaces : String
notoSansFontFaces =
    let
        latinRange : String
        latinRange =
            "U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD"

        latinExtRange : String
        latinExtRange =
            "U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF"
    in
    fontFace "TrueType" "ascii" 400 "ascii.ttf" "U+0000-FFFF"
        :: List.map
            (\weight ->
                fontFace "woff2" "Noto Sans" weight ("noto-sans-latin-" ++ String.fromInt weight ++ "-normal.woff2") latinRange
                    ++ fontFace "woff2" "Noto Sans" weight ("noto-sans-latin-ext-" ++ String.fromInt weight ++ "-normal.woff2") latinExtRange
            )
            [ 400, 500, 600, 700 ]
        |> String.concat


{-| DejaVu Sans Mono is used for all monospaced text (code blocks, login codes,
etc.) so that monospaced text also renders consistently across operating systems.
No unicode-range is set so the whole font is available.
-}
dejavuSansMonoFontFaces : String
dejavuSansMonoFontFaces =
    monoFontFace 400 "DejaVuSansMono.woff2"
        ++ monoFontFace 700 "DejaVuSansMono-Bold.woff2"


fontFace : String -> String -> Int -> String -> String -> String
fontFace format family weight fileName unicodeRange =
    """
@font-face {
  font-family: '""" ++ family ++ """';
  font-style: normal;
  font-weight: """ ++ String.fromInt weight ++ """;
  font-stretch: normal;
  font-display: swap;
  src: url(/fonts/""" ++ fileName ++ """) format('""" ++ format ++ """');
  unicode-range: """ ++ unicodeRange ++ """;
}"""


monoFontFace : Int -> String -> String
monoFontFace weight fileName =
    """
@font-face {
  font-family: 'DejaVu Sans Mono';
  font-style: normal;
  font-weight: """ ++ String.fromInt weight ++ """;
  font-stretch: normal;
  font-display: swap;
  src: url(/fonts/""" ++ fileName ++ """) format('woff2');
}"""


widthAttr : Int -> Html.Attribute msg
widthAttr width =
    Html.Attributes.style "width" (String.fromInt width ++ "px")


heightAttr : Int -> Html.Attribute msg
heightAttr height =
    Html.Attributes.style "height" (String.fromInt height ++ "px")


userLabelHtml : userId -> SeqDict userId { a | name : PersonName } -> Html msg
userLabelHtml userId allUsers =
    case SeqDict.get userId allUsers of
        Just user ->
            userLabel2Html user

        Nothing ->
            Html.span userLabelHtmlAttributes [ Html.text "@<name missing>" ]


userLabelHtmlAttributes : List (Html.Attribute msg)
userLabelHtmlAttributes =
    [ Html.Attributes.style "background-color" (colorToStyle userLabelBackground)
    , Html.Attributes.style "padding" "1px 1px 0 1px"
    , Html.Attributes.style "color" (colorToStyle userLabelFontColor)
    , Html.Attributes.style "border-radius" "2px"
    , Html.Attributes.style "white-space" "nowrap"
    ]


userLabel2Html : { a | name : PersonName } -> Html msg
userLabel2Html user =
    Html.span userLabelHtmlAttributes [ Html.text ("@" ++ PersonName.toString user.name) ]


blockClickPropagation : msg -> Ui.Attribute msg
blockClickPropagation msg =
    Ui.Events.stopPropagationOn "click" (Json.Decode.succeed ( msg, True ))


channelColumnWidth : Coord CssPixels -> Int
channelColumnWidth windowSize =
    clamp 200 300 (toFloat (Coord.xRaw windowSize) * 0.2 |> round)


channelAndGuildColumnWidth : Coord CssPixels -> Int
channelAndGuildColumnWidth windowSize =
    channelColumnWidth windowSize + 58


channelHeaderHeight : number
channelHeaderHeight =
    38


conversationWidthIgnoreScrollbar : Coord CssPixels -> Bool -> Int
conversationWidthIgnoreScrollbar windowSize showMembersTab =
    if isMobileAlt windowSize then
        Coord.xRaw windowSize

    else
        Coord.xRaw windowSize
            - ((guildIconFullWidth + 1)
                + channelColumnWidth windowSize
                + (if showMembersTab then
                    memberColumnWidth

                   else
                    0
                  )
              )


guildIconFullWidth : number
guildIconFullWidth =
    58


memberColumnWidth : number
memberColumnWidth =
    300


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


bounceScroll : Bool -> Ui.Attribute msg
bounceScroll isMobile2 =
    Ui.attrIf
        isMobile2
        (Ui.inFront (Ui.el [ Ui.height (Ui.px 1), Ui.alignBottom, Ui.move { x = 0, y = 1, z = 0 } ] Ui.none))


scrollable : Bool -> Ui.Attribute msg
scrollable canScroll2 =
    if canScroll2 then
        Ui.scrollable

    else
        Ui.clip


canScroll : Bool -> Drag -> Bool
canScroll isMobile2 drag =
    if isMobile2 then
        case drag of
            Dragging dragging ->
                not dragging.horizontalStart

            _ ->
                True

    else
        -- On desktop there's no horizontal drag gesture, so keep scrolling
        -- enabled to stop scrollbars flickering while other drags happen.
        True


isMobileAlt : Coord CssPixels -> Bool
isMobileAlt windowSize =
    Coord.xRaw windowSize < 700


noShrinking : Ui.Attribute msg
noShrinking =
    htmlStyle "flex-shrink" "0"


colorToStyle : Color -> String
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


{-| Same color as colorToStyle but in hex notation (alpha is ignored). Some
email clients don't support rgba() so email code should use this instead.
-}
colorToHex : Color -> String
colorToHex color =
    let
        { red, green, blue } =
            Color.toRgba color

        floatToHex : Float -> String
        floatToHex value =
            let
                int =
                    round (value * 255)

                digit : Int -> String
                digit a =
                    String.slice a (a + 1) "0123456789abcdef"
            in
            digit (int // 16) ++ digit (modBy 16 int)
    in
    "#" ++ floatToHex red ++ floatToHex green ++ floatToHex blue


{-| A subtle background drawn behind an image while it's still loading, so it's
clear something is there before the image finishes downloading. Once the image
loads it paints over this placeholder.
-}
imagePlaceholderStyle : Html.Attribute msg
imagePlaceholderStyle =
    Html.Attributes.style "background-color" (colorToStyle background3)


{-| Tells the browser it can wait until an image is close to the viewport before
downloading it. Only worth adding to images that can start off screen (messages
that are scrolled past, guild icons further down the sidebar, and so on), and
only safe when the image has an explicit size, otherwise the page reflows as
each one arrives.
-}
lazyLoading : Html.Attribute msg
lazyLoading =
    Html.Attributes.attribute "loading" "lazy"


colorWithAlpha : Float -> Color -> Color
colorWithAlpha alpha color =
    let
        color2 =
            Color.toRgba color
    in
    Color.fromRgba { color2 | alpha = alpha }


tabBackground : Ui.Color
tabBackground =
    background1


background1 : Ui.Color
background1 =
    Ui.rgb 4 6 20


background2 : Ui.Color
background2 =
    Ui.rgb 28 35 60


background3 : Ui.Color
background3 =
    Ui.rgb 39 50 76


inputBackground : Ui.Color
inputBackground =
    Ui.rgba 0 0 0 0.3


inputBorder : Ui.Color
inputBorder =
    Ui.rgb 79 84 102


selectedTextBackground : Ui.Color
selectedTextBackground =
    Ui.rgb 0 120 215


buttonBackground : Ui.Color
buttonBackground =
    Ui.rgb 64 122 178


disabledButtonBackground : Ui.Color
disabledButtonBackground =
    Ui.rgb 112 113 113


disabledButtonBorder : Ui.Color
disabledButtonBorder =
    Ui.rgb 140 142 143


deleteButtonBackground : Ui.Color
deleteButtonBackground =
    Ui.rgb 180 50 40


deleteButtonBorder : Ui.Color
deleteButtonBorder =
    Ui.rgb 179 67 59


deleteButtonFont : Ui.Color
deleteButtonFont =
    Ui.rgb 255 240 250


buttonBorder : Ui.Color
buttonBorder =
    Ui.rgb 101 141 181


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
    Ui.rgb 34 39 56


border2 : Ui.Color
border2 =
    Ui.rgb 17 20 28


highlightedBorder : Ui.Color
highlightedBorder =
    Ui.rgb 12 140 200


errorColor : Ui.Color
errorColor =
    Ui.rgb 240 170 180


hoverHighlight : Ui.Color
hoverHighlight =
    Ui.rgba 255 255 255 0.17


{-| Weaker version of hoverHighlight, used when hovering rows that have no
background of their own
-}
weakHoverHighlight : Ui.Color
weakHoverHighlight =
    Ui.rgba 255 255 255 0.08


{-| Background for the currently selected item in a list of channels/rows
-}
selectedHighlight : Ui.Color
selectedHighlight =
    Ui.rgba 255 255 255 0.13


{-| Dim gray for placeholder text and secondary metadata shown on dark
backgrounds
-}
dimFont : Ui.Color
dimFont =
    Ui.rgb 180 180 180


{-| Strong red for error text and dangerous state (mic muted, etc.). Icons.elm
can't import this module so the mic slash in micOff hardcodes the same color.
-}
dangerRed : Ui.Color
dangerRed =
    Ui.rgb 200 60 60


{-| Translucent black drawn behind modals or on top of images so overlaid
content stays readable
-}
scrim : Ui.Color
scrim =
    Ui.rgba 0 0 0 0.5


replyToColor : Ui.Color
replyToColor =
    Ui.rgb 51 51 118


mentionColor : Ui.Color
mentionColor =
    Ui.rgb 112 90 78


hoverAndReplyToColor : Ui.Color
hoverAndReplyToColor =
    Ui.rgb 66 66 139


hoverAndMentionColor : Ui.Color
hoverAndMentionColor =
    Ui.rgb 138 112 108


alertColor : Ui.Color
alertColor =
    Ui.rgb 255 10 40


{-| Background for inline @user mention labels in messages
-}
userLabelBackground : Ui.Color
userLabelBackground =
    Ui.rgb 32 50 218


{-| Font color for inline @user mention labels in messages
-}
userLabelFontColor : Ui.Color
userLabelFontColor =
    Ui.rgb 215 235 255



--lazyChangedValue : String -> b -> Element msg
--lazyChangedValue name value =
--    Ui.Lazy.lazy2 lazyChangedValueHelper name value
--
--
--lazyChangedValueHelper : String -> b -> Element msg
--lazyChangedValueHelper name value =
--    let
--        _ =
--            Debug.log ("Lazy change: " ++ name) ()
--    in
--    Ui.none
