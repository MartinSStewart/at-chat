module GuildIcon exposing
    ( ChannelNotificationType(..)
    , Mode(..)
    , addGuildButton
    , defaultUser
    , defaultUserHtml
    , discordLabel
    , discordLogo
    , discordNotificationView
    , discordUserView
    , discordView
    , iconFontColor
    , notificationHelper
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


{-| The Discord logo on a blurple circle. Marks the guilds and users that come
from Discord so they can be told apart from at-chat ones at a glance.
-}
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
            0
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


{-| Same as `view` but marked as coming from Discord.
-}
discordView : Mode -> { a | name : GuildName, icon : Maybe FileHash } -> Element msg
discordView mode guild =
    Ui.el
        (discordNotificationView
            0
            -3
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
                    , Ui.background MyUi.secondaryGray
                    , Ui.border 1
                    , Ui.borderColor MyUi.secondaryGrayBorder
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
        [ notificationView 0 -3 MyUi.background1 notification
        ]
        (case maybeIcon of
            Just icon ->
                iconView (FileStatus.fileUrl FileStatus.pngContent icon)

            Nothing ->
                defaultUser True size (Ui.rounded iconRounding) color
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
        |> Ui.el [ discordNotificationView 0 -3 notification ]


defaultUser : Bool -> Int -> Ui.Attribute msg -> UserColor -> Element msg
defaultUser centerX size2 rounding color =
    Ui.el
        [ Ui.contentCenterY
        , rounding
        , Ui.background (UserColor.toColor color)
        , if centerX then
            Ui.centerX

          else
            Ui.noAttr
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
so this is the same picture whatever is going on around it.
-}
iconView : String -> Element msg
iconView url =
    Html.img
        [ Html.Attributes.style "width" (String.fromInt size ++ "px")
        , Html.Attributes.style "height" (String.fromInt size ++ "px")
        , Html.Attributes.src url
        , MyUi.lazyLoading
        , Html.Attributes.style "display" "flex"
        , Html.Attributes.style "align-self" "center"
        , Html.Attributes.style "object-fit" "cover"
        , Html.Attributes.style "border-radius" (String.fromInt iconRounding ++ "px")
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


iconRounding : Int
iconRounding =
    round (toFloat size * 8 / 50)


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


{-| The curves above and below the selected icon, the way the channel header tabs have them:
the edge the icon shares with the channel list carries on past the icon and then curves back in
to meet it, so the icon reads as joined onto the channel list rather than sitting against it.

Where the guild has a picture, the picture carries on into the curves as a reflection of
itself, which puts the same row of it on both sides of the icon's edge.

-}
selectedEdgeCurves : Mode -> Maybe FileHash -> List (Ui.Attribute msg)
selectedEdgeCurves mode maybeIcon =
    case ( mode, maybeIcon ) of
        ( Normal _, _ ) ->
            []

        ( IsSelected, Just icon ) ->
            let
                url : String
                url =
                    FileStatus.fileUrl FileStatus.pngContent icon
            in
            [ curveAboveIcon [ pictureAboveIcon url ]
            , curveBelowIcon [ pictureBelowIcon url ]
            ]

        ( IsSelected, Nothing ) ->
            plainEdgeCurves


{-| The curves for the things in the column that have no picture for them to carry on into:
a guild showing its initials, and the button for making a new one.
-}
plainEdgeCurves : List (Ui.Attribute msg)
plainEdgeCurves =
    [ curveAboveIcon [ tileColor MyUi.secondaryGray ]
    , curveBelowIcon [ tileColor MyUi.secondaryGray ]
    ]


curveAboveIcon : List (Svg.Svg msg) -> Ui.Attribute msg
curveAboveIcon paint =
    Ui.inFront
        (Ui.el
            [ Ui.alignTop
            , Ui.alignRight
            , Ui.move { x = 0, y = -iconRounding, z = 0 }
            , MyUi.noPointerEvents
            ]
            (curve
                (String.join " "
                    [ "M 0,0"
                    , "L " ++ radius ++ ",0"
                    , "A " ++ radius ++ " " ++ radius ++ " 0 0 1 0," ++ radius
                    , "Z"
                    ]
                )
                paint
            )
        )


curveBelowIcon : List (Svg.Svg msg) -> Ui.Attribute msg
curveBelowIcon paint =
    Ui.inFront
        (Ui.el
            [ Ui.alignBottom
            , Ui.alignRight
            , Ui.move { x = 0, y = iconRounding, z = 0 }
            , MyUi.noPointerEvents
            ]
            (curve
                (String.join " "
                    [ "M 0," ++ radius
                    , "L " ++ radius ++ "," ++ radius
                    , "A " ++ radius ++ " " ++ radius ++ " 0 0 0 0,0"
                    , "Z"
                    ]
                )
                paint
            )
        )


{-| A box the size of the icon's corner radius, holding `paint` with the colour of the column
painted back over `cutCorner`. Taking a corner back out of it is what leaves a curve that bends
towards the icon instead of a square sitting on the end of it.
-}
curve : String -> List (Svg.Svg msg) -> Element msg
curve cutCorner paint =
    Svg.svg
        [ Svg.Attributes.width radius
        , Svg.Attributes.height radius
        , Svg.Attributes.viewBox ("0 0 " ++ radius ++ " " ++ radius)
        , Svg.Attributes.style "display:block"
        ]
        (paint
            ++ [ Svg.path
                    [ Svg.Attributes.d cutCorner
                    , Svg.Attributes.fill (MyUi.colorToStyle MyUi.background1)
                    ]
                    []
               ]
        )
        |> Ui.html


{-| The icon's picture reflected in the icon's top edge. The curve sits directly above that
edge, so the reflection puts the same row of the picture on both sides of it.
-}
pictureAboveIcon : String -> Svg.Svg msg
pictureAboveIcon url =
    Svg.image
        [ Svg.Attributes.xlinkHref url
        , Svg.Attributes.x (String.fromInt (iconRounding - size))
        , Svg.Attributes.y radius
        , Svg.Attributes.width (String.fromInt size)
        , Svg.Attributes.height (String.fromInt size)
        , -- Matches the object-fit the icon itself is drawn with, so a picture that isn't
          -- square is cropped the same way in both places
          Svg.Attributes.preserveAspectRatio "xMidYMid slice"
        , Svg.Attributes.transform
            ("translate(0," ++ String.fromInt (iconRounding * 2) ++ ") scale(1,-1)")
        ]
        []


{-| The same reflection in the icon's bottom edge.
-}
pictureBelowIcon : String -> Svg.Svg msg
pictureBelowIcon url =
    Svg.image
        [ Svg.Attributes.xlinkHref url
        , Svg.Attributes.x (String.fromInt (iconRounding - size))
        , Svg.Attributes.y (String.fromInt -size)
        , Svg.Attributes.width (String.fromInt size)
        , Svg.Attributes.height (String.fromInt size)
        , Svg.Attributes.preserveAspectRatio "xMidYMid slice"
        , Svg.Attributes.transform "scale(1,-1)"
        ]
        []


{-| What a guild with no picture has in place of one: the colour its initials are drawn on.
-}
tileColor : Ui.Color -> Svg.Svg msg
tileColor color =
    Svg.rect
        [ Svg.Attributes.width "100%"
        , Svg.Attributes.height "100%"
        , Svg.Attributes.fill (MyUi.colorToStyle color)
        ]
        []


radius : String
radius =
    String.fromInt iconRounding


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
         , Ui.background MyUi.secondaryGray
         , Ui.border 1
         , Ui.borderColor MyUi.secondaryGrayBorder
         , Ui.width (Ui.px size)
         , Ui.height (Ui.px size)
         , Ui.padding 8
         , Ui.Font.color iconFontColor
         , MyUi.hoverText "Create new guild"
         ]
            ++ (if isSelected then
                    plainEdgeCurves

                else
                    []
               )
        )
        (Ui.html Icons.plusIcon)


showFriendsButton : msg -> Element msg
showFriendsButton onPress =
    MyUi.elButton
        (Dom.id "guildIcon_showFriends")
        onPress
        [ Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.centerX
        , Ui.rounded iconRounding
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
