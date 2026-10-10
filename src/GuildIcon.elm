module GuildIcon exposing
    ( ChannelNotificationType(..)
    , Mode(..)
    , addGuildButton
    , columnBorderView
    , defaultUser
    , defaultUserHtml
    , discordLogo
    , discordNotificationView
    , discordUserView
    , iconFontColor
    , notificationView
    , showFriendsButton
    , userView
    , view
    )

import Color.Manipulate
import Discord
import Effect.Browser.Dom as Dom exposing (HtmlId)
import FileStatus exposing (FileHash)
import GuildName exposing (GuildName)
import Html exposing (Html)
import Html.Attributes
import Icons
import MyUi
import OneOrGreater exposing (OneOrGreater)
import Svg
import Svg.Attributes
import Ui exposing (Element)
import Ui.Accessibility
import Ui.Font
import UserColor exposing (UserColor)


type Mode
    = Normal ChannelNotificationType
    | IsSelected


type ChannelNotificationType
    = NoNotification
    | NewMessage OneOrGreater
    | NewMessageForUser OneOrGreater


maxNotifications : number
maxNotifications =
    99


{-| Height of the notification count, and of the Discord marker that shares its
corner.
-}
notificationHeight : number
notificationHeight =
    17


notificationHelper : Ui.Color -> Ui.Color -> Ui.Color -> Int -> Int -> OneOrGreater -> Ui.Attribute msg
notificationHelper color fontColor borderColor xOffset yOffset count =
    let
        count2 : Int
        count2 =
            OneOrGreater.toInt count
    in
    Html.div
        [ Html.Attributes.style "display" "flex" ]
        (if count2 > maxNotifications then
            [ Icons.infinity 14 ]

         else
            Icons.numbers 7 (String.fromInt count2)
        )
        |> Ui.html
        |> Ui.el
            [ Ui.rounded 99
            , Ui.background color
            , Ui.width
                (Ui.px
                    (if count2 < 10 then
                        notificationHeight

                     else
                        22
                    )
                )
            , Ui.height (Ui.px notificationHeight)
            , Ui.border 2
            , Ui.borderColor borderColor
            , Ui.move { x = xOffset, y = yOffset, z = 0 }
            , Ui.alignRight
            , Ui.Font.color fontColor
            , Ui.contentCenterX
            , Ui.contentCenterY
            , Ui.Accessibility.description (String.fromInt count2)
            ]
        |> Ui.inFront


notificationView : Int -> Int -> Ui.Color -> ChannelNotificationType -> Ui.Attribute msg
notificationView xOffset yOffset borderColor notification =
    case notification of
        NoNotification ->
            Ui.noAttr

        NewMessage count ->
            notificationHelper MyUi.white MyUi.black borderColor xOffset yOffset count

        NewMessageForUser count ->
            notificationHelper MyUi.alertColor MyUi.white borderColor xOffset yOffset count


discordLogo : Element msg
discordLogo =
    Ui.el
        [ Ui.background discordBlurple
        , Ui.rounded 99
        , Ui.padding 3
        , Ui.border 1
        , Ui.borderColor MyUi.background1
        , Ui.width Ui.shrink
        , MyUi.noShrinking
        , Ui.Accessibility.description discordLabel
        ]
        (Ui.html Icons.discord)


discordLabel : String
discordLabel =
    "Discord"


discordBlurple : Ui.Color
discordBlurple =
    Ui.rgb 88 101 242


discordBlurpleDark : Ui.Color
discordBlurpleDark =
    Color.Manipulate.weightedMix MyUi.background1 discordBlurple 0.3


discordBlurpleFont : Ui.Color
discordBlurpleFont =
    Ui.rgb 193 197 239


{-| Stands in for `notificationView` on guilds and users that come from Discord.
The Discord logo takes the corner the notification count would use, and gives it
back up whenever there is a count to show.
-}
discordNotificationView : Int -> Int -> ChannelNotificationType -> Ui.Attribute msg
discordNotificationView xOffset yOffset notification =
    case notification of
        NoNotification ->
            Ui.el
                [ Ui.rounded 99
                , Ui.background discordBlurpleDark
                , Ui.width (Ui.px notificationHeight)
                , Ui.height (Ui.px notificationHeight)
                , Ui.move { x = xOffset, y = yOffset, z = 0 }
                , Ui.alignRight
                , Ui.contentCenterX
                , Ui.contentCenterY
                , Ui.Font.color discordBlurpleFont
                , Ui.Accessibility.description discordLabel
                , -- The icon is inside a link. Letting the marker swallow clicks
                  -- would leave a dead spot in the corner of it.
                  MyUi.noPointerEvents
                ]
                (Ui.html Icons.discord)
                |> Ui.inFront

        NewMessage count ->
            notificationHelper MyUi.white MyUi.black discordBlurpleDark xOffset yOffset count

        NewMessageForUser count ->
            notificationHelper MyUi.alertColor MyUi.white discordBlurpleDark xOffset yOffset count


view : Mode -> { a | name : GuildName, icon : Maybe FileHash } -> Element msg
view mode guild =
    Ui.el
        (notificationView
            -4
            -3
            MyUi.background1
            (case mode of
                IsSelected ->
                    NoNotification

                Normal notification ->
                    notification
            )
            :: selectedEdgeCurves mode guild.icon
        )
        (guildIcon guild mode (GuildName.toString guild.name))


guildIcon : { a | icon : Maybe FileHash } -> Mode -> String -> Element msg
guildIcon guild mode name =
    case guild.icon of
        Just icon ->
            guildIconView mode (FileStatus.fileUrl FileStatus.pngContent icon)

        Nothing ->
            String.replace "-" " " name
                |> String.filter (\char -> Char.isAlphaNum char || char == ' ')
                |> String.words
                |> List.take 3
                |> List.map (String.left 1)
                |> String.concat
                |> Ui.text
                |> Ui.el
                    [ Ui.contentCenterX
                    , Ui.contentCenterY
                    , case mode of
                        IsSelected ->
                            selectedRounding

                        Normal _ ->
                            notSelectedRounding
                    , MyUi.notoSans
                    , Ui.Font.weight 600
                    , Ui.background
                        (case mode of
                            IsSelected ->
                                Ui.rgba 0 0 0 0

                            Normal _ ->
                                MyUi.secondaryGray
                        )
                    , case mode of
                        IsSelected ->
                            Ui.alignRight

                        Normal _ ->
                            Ui.alignLeft
                    , Ui.width (Ui.px size)
                    , Ui.height (Ui.px size)
                    , Ui.Font.size (round (toFloat size * 18 / 50))
                    , Ui.Font.color iconFontColor
                    , MyUi.hoverText name
                    ]


userView : ChannelNotificationType -> Maybe FileHash -> UserColor -> Element msg
userView notification maybeIcon color =
    Ui.el
        [ notificationView -4 -3 MyUi.background1 notification
        ]
        (case maybeIcon of
            Just icon ->
                iconView (FileStatus.fileUrl FileStatus.pngContent icon)

            Nothing ->
                defaultUser size notSelectedRounding color
        )


discordUserView : ChannelNotificationType -> Maybe FileHash -> Discord.Id Discord.UserId -> Element msg
discordUserView notification maybeIcon userId =
    (case maybeIcon of
        Just icon ->
            FileStatus.fileUrl FileStatus.pngContent icon

        Nothing ->
            Discord.defaultUserAvatarUrl (Discord.TwoToNthPower 7) userId
    )
        |> iconView
        |> Ui.el [ discordNotificationView -4 -3 notification ]


defaultUser : Int -> Ui.Attribute msg -> UserColor -> Element msg
defaultUser size2 rounding color =
    Ui.el
        [ Ui.contentCenterY
        , rounding
        , Ui.background (UserColor.toColor color)
        , Ui.width (Ui.px size2)
        , Ui.height (Ui.px size2)
        , Ui.paddingXY 4 0
        , Ui.Font.color iconFontColor
        , -- We need no pointer events here so drawing anchoring gets the offset of the parent
          MyUi.noPointerEvents
        ]
        (Ui.html Icons.person)


defaultUserHtml : Int -> Int -> UserColor -> Html msg
defaultUserHtml size2 rounded color =
    Html.div
        [ Html.Attributes.style "border-radius" (String.fromInt rounded ++ "px")
        , Html.Attributes.style "background-color" (UserColor.toColor color |> MyUi.colorToStyle)
        , Html.Attributes.style "width" (String.fromInt (size2 - 8) ++ "px")
        , Html.Attributes.style "height" (String.fromInt (size2 - 8) ++ "px")
        , Html.Attributes.style "padding" "4px"
        , Html.Attributes.style "color" (MyUi.colorToStyle iconFontColor)
        , Html.Attributes.style "flex-shrink" "0"
        ]
        [ Icons.person ]


{-| A guild's own picture. It gets a background of its own so that a picture with
transparency in it still fills the tile, which is what the selected guild is recognised by.
-}
guildIconView : Mode -> String -> Element msg
guildIconView mode url =
    Html.img
        [ Html.Attributes.style "width" (String.fromInt size ++ "px")
        , Html.Attributes.style "height" (String.fromInt size ++ "px")
        , Html.Attributes.src url
        , MyUi.lazyLoading
        , Html.Attributes.style "display" "flex"
        , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.guildIconBackground)
        , Html.Attributes.style "opacity"
            (case mode of
                IsSelected ->
                    "0"

                Normal _ ->
                    "1"
            )
        , Html.Attributes.style
            "align-self"
            (case mode of
                IsSelected ->
                    "flex-end"

                Normal _ ->
                    "flex-start"
            )
        , Html.Attributes.style "object-fit" "cover"
        , Html.Attributes.style
            "border-radius"
            (case mode of
                IsSelected ->
                    String.fromInt iconRounding ++ "px 0 0 " ++ String.fromInt iconRounding ++ "px"

                Normal _ ->
                    "0 " ++ String.fromInt iconRounding ++ "px " ++ String.fromInt iconRounding ++ "px 0"
            )
        ]
        []
        |> Ui.html


{-| A user's avatar. Unlike a guild, a user is never the selected thing in the guild column,
so this is the same picture whatever is going on around it: the one an unselected guild
shows, sitting against the edge of the column with its outer corners rounded.
-}
iconView : String -> Element msg
iconView url =
    Html.img
        [ Html.Attributes.style "width" (String.fromInt size ++ "px")
        , Html.Attributes.style "height" (String.fromInt size ++ "px")
        , Html.Attributes.src url
        , MyUi.lazyLoading
        , Html.Attributes.style "display" "flex"
        , Html.Attributes.style "align-self" "flex-start"
        , Html.Attributes.style "object-fit" "cover"
        , Html.Attributes.style
            "border-radius"
            ("0 " ++ String.fromInt iconRounding ++ "px " ++ String.fromInt iconRounding ++ "px 0")
        ]
        []
        |> Ui.html


{-| Font color for icons and initials drawn on top of the light colored
guild/user tiles
-}
iconFontColor : Ui.Color
iconFontColor =
    Ui.rgba 0 0 0 0.8


size : number
size =
    50


{-| Match the curves' stroke and horizontal SVG origin: CSS borders and separate
SVG origins round differently at fractional zoom. Draw the rounded corner rather
than clipping a straight line to it. Native SVG coordinates keep the corner radius
and stroke width fixed while the column stretches.
-}
columnBorderView : Int -> Element msg
columnBorderView safeAreaInsetTop =
    let
        topLeftRadius : Int
        topLeftRadius =
            safeAreaInsetTop // 2

        x : String
        x =
            String.fromFloat (toFloat size - 0.5)

        radius : String
        radius =
            String.fromFloat (toFloat topLeftRadius - 0.5)
    in
    Svg.svg
        [ Svg.Attributes.width (String.fromInt size)
        , Svg.Attributes.height "100%"
        , Svg.Attributes.style "display:block;overflow:visible;position:absolute;right:0;top:0"
        ]
        (Svg.line
            [ Svg.Attributes.x1 x
            , Svg.Attributes.x2 x
            , Svg.Attributes.y1 (String.fromInt topLeftRadius)
            , Svg.Attributes.y2 "100%"
            , Svg.Attributes.stroke (MyUi.colorToStyle MyUi.guildColumnBorder)
            , Svg.Attributes.strokeWidth "var(--guild-outline-width, 1px)"
            ]
            []
            :: (if topLeftRadius > 0 then
                    [ Svg.path
                        [ Svg.Attributes.d
                            ("M "
                                ++ x
                                ++ ","
                                ++ String.fromInt topLeftRadius
                                ++ " A "
                                ++ radius
                                ++ " "
                                ++ radius
                                ++ " 0 0 1 "
                                ++ String.fromInt (size + topLeftRadius - 1)
                                ++ ",0.5"
                            )
                        , Svg.Attributes.fill "none"
                        , Svg.Attributes.strokeLinecap "square"
                        , Svg.Attributes.stroke (MyUi.colorToStyle MyUi.guildColumnBorder)
                        , Svg.Attributes.strokeWidth "var(--guild-outline-width, 1px)"
                        ]
                        []
                    ]

                else
                    []
               )
        )
        |> Ui.html
        |> Ui.el [ Ui.width (Ui.px 1), Ui.height Ui.fill, Ui.alignLeft, MyUi.htmlStyle "position" "relative", MyUi.noPointerEvents ]
        |> Ui.el
            [ Ui.height Ui.fill
            , MyUi.noPointerEvents
            , if safeAreaInsetTop > 0 then
                Svg.svg
                    [ Svg.Attributes.width "100%"
                    , Svg.Attributes.height "1"
                    , Svg.Attributes.style "display:block;position:absolute;left:0;top:0"
                    ]
                    [ Svg.line
                        [ Svg.Attributes.x1 (String.fromFloat (max 0.5 (toFloat topLeftRadius)))
                        , Svg.Attributes.x2 "100%"
                        , Svg.Attributes.y1 "0.5"
                        , Svg.Attributes.y2 "0.5"
                        , Svg.Attributes.stroke (MyUi.colorToStyle MyUi.guildColumnBorder)
                        , Svg.Attributes.strokeWidth "var(--guild-outline-width, 1px)"
                        ]
                        []
                    ]
                    |> Ui.html
                    |> Ui.inFront

              else
                Ui.noAttr
            ]


iconRounding : Int
iconRounding =
    round (toFloat size * 10 / 50)


selectedRounding : Ui.Attribute msg
selectedRounding =
    Ui.roundedWith
        { topLeft = iconRounding
        , topRight = 0
        , bottomLeft = iconRounding
        , bottomRight = 0
        }


notSelectedRounding : Ui.Attribute msg
notSelectedRounding =
    Ui.roundedWith
        { topLeft = 0
        , topRight = iconRounding
        , bottomLeft = 0
        , bottomRight = iconRounding
        }


{-| Keep the selected artwork mounted to preload its images. The whole tile and its
reflections are painted together, with no independently clipped edges at their joins.
It sits behind the initials, but above the neighbouring channel column's border.
-}
selectedEdgeCurves : Mode -> Maybe FileHash -> List (Ui.Attribute msg)
selectedEdgeCurves mode maybeIcon =
    [ MyUi.htmlStyle "z-index"
        (case mode of
            IsSelected ->
                "1"

            Normal _ ->
                "0"
        )
    , Ui.behindContent
        (Ui.el
            [ Ui.alignRight
            , Ui.width (Ui.px size)
            , Ui.move { x = 0, y = -invertedRadius, z = 0 }
            , MyUi.noPointerEvents
            , MyUi.htmlStyle "visibility"
                (case mode of
                    IsSelected ->
                        "visible"

                    Normal _ ->
                        "hidden"
                )
            ]
            (selectedTile maybeIcon)
        )
    ]


{-| One pattern paints the picture and its reflection across the entire silhouette.
Using separate SVGs clips both sides of a join independently, leaving an antialiased
hairline at fractional zoom. The silhouette has no stroke on its open right edge.
-}
selectedTile : Maybe FileHash -> Element msg
selectedTile maybeIcon =
    let
        height : Int
        height =
            size + 2 * invertedRadius

        id : String
        id =
            Maybe.map FileStatus.fileHashToString maybeIcon |> Maybe.withDefault "plain"

        gradientId : String
        gradientId =
            "guildIconOutline_" ++ id

        patternId : String
        patternId =
            "guildIconPicture_" ++ id
    in
    Svg.svg
        [ Svg.Attributes.width (String.fromInt size)
        , Svg.Attributes.height (String.fromInt height)
        , Svg.Attributes.viewBox ("0 " ++ String.fromInt -invertedRadius ++ " " ++ String.fromInt size ++ " " ++ String.fromInt height)
        , Svg.Attributes.style "display:block;overflow:visible"
        ]
        [ Svg.defs
            []
            (Svg.linearGradient
                [ Svg.Attributes.id gradientId
                , Svg.Attributes.gradientUnits "userSpaceOnUse"
                , Svg.Attributes.x1 "0"
                , Svg.Attributes.x2 "0"
                , Svg.Attributes.y1 (String.fromInt -invertedRadius)
                , Svg.Attributes.y2 (String.fromInt (size + invertedRadius))
                ]
                [ Svg.stop
                    [ Svg.Attributes.offset "0"
                    , Svg.Attributes.stopColor (MyUi.colorToStyle MyUi.guildColumnBorder)
                    ]
                    []
                , Svg.stop
                    [ Svg.Attributes.offset (String.fromFloat ((toFloat invertedRadius - 0.5) / toFloat height))
                    , Svg.Attributes.stopColor (MyUi.colorToStyle MyUi.guildIconSelectedBorder)
                    ]
                    []
                , Svg.stop
                    [ Svg.Attributes.offset (String.fromFloat ((toFloat (size + invertedRadius) + 0.5) / toFloat height))
                    , Svg.Attributes.stopColor (MyUi.colorToStyle MyUi.guildIconSelectedBorder)
                    ]
                    []
                , Svg.stop
                    [ Svg.Attributes.offset "1"
                    , Svg.Attributes.stopColor (MyUi.colorToStyle MyUi.guildColumnBorder)
                    ]
                    []
                ]
                :: (case maybeIcon of
                        Nothing ->
                            []

                        Just icon ->
                            let
                                url : String
                                url =
                                    FileStatus.fileUrl FileStatus.pngContent icon
                            in
                            [ Svg.pattern
                                [ Svg.Attributes.id patternId
                                , Svg.Attributes.patternUnits "userSpaceOnUse"
                                , Svg.Attributes.width (String.fromInt size)
                                , Svg.Attributes.height (String.fromInt (size * 2))
                                ]
                                [ Svg.rect
                                    [ Svg.Attributes.width (String.fromInt size)
                                    , Svg.Attributes.height (String.fromInt (size * 2))
                                    , Svg.Attributes.fill (MyUi.colorToStyle MyUi.guildIconBackground)
                                    ]
                                    []
                                , Svg.image
                                    [ Svg.Attributes.xlinkHref url
                                    , Svg.Attributes.width (String.fromInt size)
                                    , Svg.Attributes.height (String.fromInt size)
                                    , Svg.Attributes.preserveAspectRatio "xMidYMid slice"
                                    ]
                                    []
                                , Svg.image
                                    [ Svg.Attributes.xlinkHref url
                                    , Svg.Attributes.width (String.fromInt size)
                                    , Svg.Attributes.height (String.fromInt size)
                                    , Svg.Attributes.preserveAspectRatio "xMidYMid slice"
                                    , Svg.Attributes.transform ("translate(0," ++ String.fromInt (size * 2) ++ ") scale(1,-1)")
                                    ]
                                    []
                                ]
                            ]
                   )
            )
        , Svg.path
            [ Svg.Attributes.d selectedShape
            , Svg.Attributes.fill
                (case maybeIcon of
                    Nothing ->
                        MyUi.colorToStyle MyUi.secondaryGray

                    Just _ ->
                        "url(#" ++ patternId ++ ")"
                )
            ]
            []
        , Svg.path
            [ Svg.Attributes.d selectedOutline
            , Svg.Attributes.fill "none"
            , Svg.Attributes.stroke ("url(#" ++ gradientId ++ ")")
            , Svg.Attributes.strokeWidth "var(--guild-outline-width, 1px)"
            ]
            []
        ]
        |> Ui.html


selectedShape : String
selectedShape =
    selectedOutline ++ " H " ++ String.fromInt size ++ " V " ++ String.fromInt -invertedRadius ++ " Z"


{-| The fill follows this exact contour so the stroke overlaps it rather than
merely touching a separately offset edge. The mirrored circular arcs meet the
centre of the column border; only the fill closes over that border on the right.
-}
selectedOutline : String
selectedOutline =
    let
        arc : String
        arc =
            "A " ++ String.fromFloat (toFloat invertedRadius - 0.5) ++ " " ++ String.fromFloat (toFloat invertedRadius - 0.5) ++ " 0 0 1 "

        corner : String
        corner =
            "A " ++ String.fromFloat (toFloat iconRounding + 0.5) ++ " " ++ String.fromFloat (toFloat iconRounding + 0.5) ++ " 0 0 0 "
    in
    String.join " "
        [ "M " ++ String.fromFloat (toFloat size - 0.5) ++ "," ++ String.fromInt -invertedRadius
        , arc ++ String.fromInt (size - invertedRadius) ++ ",-0.5"
        , "H " ++ String.fromInt iconRounding
        , corner ++ "-0.5," ++ String.fromInt iconRounding
        , "V " ++ String.fromInt (size - iconRounding)
        , corner ++ String.fromInt iconRounding ++ "," ++ String.fromFloat (toFloat size + 0.5)
        , "H " ++ String.fromInt (size - invertedRadius)
        , arc ++ String.fromFloat (toFloat size - 0.5) ++ "," ++ String.fromInt (size + invertedRadius)
        ]


invertedRadius : Int
invertedRadius =
    iconRounding + 6


addGuildButton : HtmlId -> Bool -> msg -> Element msg
addGuildButton htmlId isSelected onPress =
    MyUi.elButton
        htmlId
        onPress
        ([ Ui.contentCenterX
         , Ui.contentCenterY
         , if isSelected then
            Ui.alignRight

           else
            Ui.alignLeft
         , if isSelected then
            selectedRounding

           else
            notSelectedRounding
         , MyUi.notoSans
         , Ui.Font.weight 600
         , Ui.background
            (if isSelected then
                Ui.rgba 0 0 0 0

             else
                MyUi.secondaryGray
            )
         , Ui.border
            (if isSelected then
                0

             else
                1
            )
         , Ui.borderColor MyUi.secondaryGrayBorder
         , Ui.width (Ui.px size)
         , Ui.height (Ui.px size)
         , Ui.padding 8
         , Ui.Font.color iconFontColor
         , MyUi.hoverText "Create new guild"
         ]
            ++ selectedEdgeCurves
                (if isSelected then
                    IsSelected

                 else
                    Normal NoNotification
                )
                Nothing
        )
        (Ui.el [] (Ui.html Icons.plusIcon))


showFriendsButton : msg -> Element msg
showFriendsButton onPress =
    MyUi.elButton
        (Dom.id "guildIcon_showFriends")
        onPress
        [ Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.alignLeft
        , notSelectedRounding
        , MyUi.notoSans
        , Ui.Font.weight 600
        , Ui.background MyUi.secondaryGray
        , Ui.border 1
        , Ui.borderColor MyUi.secondaryGrayBorder
        , Ui.width (Ui.px size)
        , Ui.height (Ui.px size)
        , Ui.padding 8
        , Ui.Font.color iconFontColor
        , MyUi.hoverText "Show friends list"
        ]
        (Ui.html Icons.userGroup)
