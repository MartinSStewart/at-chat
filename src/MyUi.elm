module MyUi exposing
    ( column
    , contentContainerAttributes
    , datestamp
    , deleteButton
    , emailAddress
    , emailAddressLink
    , errorBox
    , errorColor
    , fontCss
    , gray
    , green500
    , heightAttr
    , hoverText
    , internalLink
    , label
    , listToText
    , montserrat
    , noPointerEvents
    , padding
    , primaryButton
    , radioRowWithSeparators
    , rounded
    , row
    , secondaryButton
    , secondaryGray
    , secondaryGrayBorder
    , textLinkColor
    , timeElapsedView
    , touchPress
    , userLabel
    , userLabel2
    , white
    , widthAttr
    )

import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import EmailAddress exposing (EmailAddress)
import Html exposing (Html)
import Html.Attributes
import Html.Events.Extra.Touch
import Icons
import Id exposing (Id, UserId)
import PersonName exposing (PersonName)
import Quantity
import Round
import Route exposing (Route, UserOverviewRouteData(..))
import SeqDict exposing (SeqDict)
import Time exposing (Month(..))
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Shadow


rhythm : number
rhythm =
    8


padding : Ui.Attribute msg
padding =
    Ui.padding rhythm


spacing : Ui.Attribute msg
spacing =
    Ui.spacing rhythm


rounded : Ui.Attribute msg
rounded =
    Ui.rounded rhythm


{-| Row with preapplied standard spacing.
-}
row : List (Ui.Attribute msg) -> List (Element msg) -> Element msg
row attrs children =
    Ui.row (spacing :: attrs) children


{-| Column with preapplied standard spacing.
-}
column : List (Ui.Attribute msg) -> List (Element msg) -> Element msg
column attrs children =
    Ui.column (spacing :: attrs) children


errorBox : HtmlId -> (String -> msg) -> String -> Element msg
errorBox id onPress error =
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
        , Ui.row
            [ Ui.width Ui.shrink
            , Ui.paddingWith { left = 0, right = 4, top = 2, bottom = 2 }

            -- We can't use touchPress here. iPads don't let you trigger clipboard copy on touch start.
            , Ui.Input.button (onPress error)
            , Dom.idToString id |> Ui.id
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



--++ ":"
--++ String.padLeft 2 '0' (String.fromInt (Time.toSecond Time.utc time))


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
    Ui.rgb 245 245 245


secondaryGrayBorder : Ui.Color
secondaryGrayBorder =
    Ui.rgb 215 215 215


unselectedGray : Ui.Color
unselectedGray =
    Ui.rgb 220 220 220


textLinkColor : Ui.Color
textLinkColor =
    Ui.rgb 66 93 203


errorColor : Ui.Color
errorColor =
    Ui.rgb 200 0 0


emailAddress : EmailAddress -> Element msg
emailAddress emailAddress2 =
    Ui.el [ Ui.Font.bold ] (Ui.text (EmailAddress.toString emailAddress2))


emailAddressLink : EmailAddress -> Element msg
emailAddressLink emailAddress2 =
    Ui.el
        [ Ui.link ("mailto:" ++ EmailAddress.toString emailAddress2)
        , Ui.Font.color textLinkColor
        , Ui.Font.underline
        ]
        (Ui.text (EmailAddress.toString emailAddress2))


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
    Html.Attributes.style "pointer-events" "none" |> Ui.htmlAttribute



-- Buttons --


unselectedBackground : Ui.Attribute msg
unselectedBackground =
    Ui.background unselectedGray


button : List (Ui.Attribute msg) -> String -> Element msg
button attrs text =
    Ui.el
        ([ Ui.paddingXY 8 4
         , rounded
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


buttonShadows : List { color : Ui.Color, x : Float, y : Float, blur : Float, size : Float }
buttonShadows =
    [ { color = Ui.rgba 0 0 0 0.1, x = 0, y = 2, blur = 4, size = -1 }
    , { color = Ui.rgba 0 0 0 0.1, x = 0, y = 0, blur = 2, size = -2 }
    ]


primaryButton : HtmlId -> msg -> String -> Element msg
primaryButton id onPress text =
    button
        [ Ui.Input.button onPress
        , Dom.idToString id |> Ui.id
        ]
        text


touchPress : msg -> Ui.Attribute msg
touchPress onPress =
    Html.Events.Extra.Touch.onStart (\_ -> onPress) |> Ui.htmlAttribute


contentContainerAttributes : List (Ui.Attribute msg)
contentContainerAttributes =
    [ Ui.paddingWith { left = 8, right = 8, top = 16, bottom = 64 }
    , Ui.centerX
    , Ui.widthMax 1000
    ]


montserrat : Ui.Attribute msg
montserrat =
    Ui.Font.family [ Ui.Font.typeface "Montserrat", Ui.Font.typeface "Helvetica", Ui.Font.sansSerif ]


internalLink : Route -> Ui.Attribute msg
internalLink route =
    Ui.link (Route.encode route)


secondaryButton : HtmlId -> List (Ui.Attribute msg) -> msg -> String -> Element msg
secondaryButton id attrs onPress label2 =
    button
        ([ Ui.Input.button onPress
         , Dom.idToString id |> Ui.id
         , Ui.background secondaryGray
         , Ui.borderColor secondaryGrayBorder
         , Ui.Font.color (Ui.rgb 0 0 0)
         ]
            ++ attrs
        )
        label2


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
        Icons.delete


hoverText : String -> Ui.Attribute msg
hoverText text =
    Ui.htmlAttribute (Html.Attributes.title text)


fontCss : Html msg
fontCss =
    Html.node "style"
        []
        [ Html.text
            (fontFace 800 "Montserrat-ExtraBold"
                ++ fontFace 700 "Montserrat-Bold"
                ++ fontFace 600 "Montserrat-SemiBold"
                ++ fontFace 500 "Montserrat-Medium"
                ++ fontFace 400 "Montserrat-Regular"
                ++ fontFace 300 "Montserrat-Light"
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


listToText : List String -> String
listToText list =
    case List.reverse list of
        [] ->
            ""

        [ single ] ->
            single

        [ one, two ] ->
            two ++ " and " ++ one

        one :: many ->
            String.join ", " (List.reverse many) ++ ", and " ++ one


userLabel : Id UserId -> SeqDict (Id UserId) { a | name : PersonName } -> Element msg
userLabel userId allUsers =
    case SeqDict.get userId allUsers of
        Just user ->
            userLabel2 user

        Nothing ->
            Ui.el
                [ errorBackground
                , Ui.width Ui.shrink
                , Ui.paddingXY 4 0
                , Ui.Font.color (Ui.rgb 50 70 240)
                , Ui.rounded 2
                , Ui.link (Route.encode (Route.UserOverviewRoute (SpecificUserRoute userId)))
                ]
                (Ui.text "<name missing>")


userLabel2 : { a | name : PersonName } -> Element msg
userLabel2 user =
    Ui.el
        [ Ui.background labelBackgroundColor
        , Ui.width Ui.shrink
        , Ui.paddingWith { left = 1, right = 1, top = 0, bottom = 1 }
        , Ui.Font.color labelFontColor
        , Ui.rounded 2
        , Ui.Font.noWrap
        ]
        (Ui.text ("@" ++ PersonName.toString user.name))


labelBackgroundColor : Ui.Color
labelBackgroundColor =
    Ui.rgb 215 235 255


labelFontColor : Ui.Color
labelFontColor =
    Ui.rgb 50 70 240
