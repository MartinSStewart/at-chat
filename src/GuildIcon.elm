module GuildIcon exposing
    ( ChannelNotificationType(..)
    , Mode(..)
    , addGuildButton
    , defaultUser
    , defaultUserHtml
    , discordUserView
    , fullWidth
    , notificationHelper
    , notificationView
    , showFriendsButton
    , userView
    , view
    )

import Discord
import Effect.Browser.Dom as Dom exposing (HtmlId)
import FileStatus exposing (FileHash)
import GuildName exposing (GuildName)
import Html exposing (Html)
import Html.Attributes
import Icons
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import MyUi
import OneOrGreater exposing (OneOrGreater)
import Ui exposing (Element)
import Ui.Accessibility
import Ui.Font


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
                        17

                     else
                        22
                    )
                )
            , Ui.height (Ui.px 17)
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


view : Mode -> { a | name : GuildName, icon : Maybe FileHash } -> Element msg
view mode guild =
    let
        name : String
        name =
            GuildName.toString guild.name
    in
    Ui.el
        [ case mode of
            IsSelected ->
                Ui.noAttr

            Normal notification ->
                notificationView 0 -3 MyUi.background1 notification
        ]
        (case guild.icon of
            Just icon ->
                iconView mode (FileStatus.fileUrl FileStatus.pngContent icon)

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
                                Ui.noAttr

                            _ ->
                                Ui.rounded (round (toFloat size * 8 / 50))
                        , MyUi.notoSans
                        , Ui.Font.weight 600
                        , Ui.background MyUi.secondaryGray
                        , Ui.border 1
                        , Ui.borderColor MyUi.secondaryGrayBorder
                        , Ui.centerX
                        , case mode of
                            IsSelected ->
                                Ui.width (Ui.px fullWidth)

                            _ ->
                                Ui.width (Ui.px size)
                        , Ui.height (Ui.px size)
                        , Ui.Font.size (round (toFloat size * 18 / 50))
                        , Ui.Font.color iconFontColor
                        , MyUi.hoverText name
                        ]
        )


userView : ChannelNotificationType -> Maybe FileHash -> Id UserId -> Element msg
userView notification maybeIcon userId =
    Ui.el
        [ notificationView 0 -3 MyUi.background1 notification
        ]
        (case maybeIcon of
            Just icon ->
                iconView (Normal notification) (FileStatus.fileUrl FileStatus.pngContent icon)

            Nothing ->
                defaultUser True size (round (toFloat size * 8 / 50)) userId
        )


discordUserView : ChannelNotificationType -> Maybe FileHash -> Discord.Id Discord.UserId -> Element msg
discordUserView notification maybeIcon userId =
    (case maybeIcon of
        Just icon ->
            FileStatus.fileUrl FileStatus.pngContent icon

        Nothing ->
            Discord.defaultUserAvatarUrl (Discord.TwoToNthPower 7) userId
    )
        |> iconView (Normal notification)
        |> Ui.el [ notificationView 0 -3 MyUi.background1 notification ]


defaultUser : Bool -> Int -> Int -> Id UserId -> Element msg
defaultUser centerX size2 rounded userId =
    Ui.el
        [ Ui.contentCenterY
        , Ui.rounded rounded
        , Ui.background (userDefaultColor userId)
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


defaultUserHtml : Int -> Int -> Id UserId -> Html msg
defaultUserHtml size2 rounded userId =
    Html.div
        [ Html.Attributes.style "border-radius" (String.fromInt rounded ++ "px")
        , Html.Attributes.style "background-color" (userDefaultColor userId |> MyUi.colorToStyle)
        , Html.Attributes.style "width" (String.fromInt (size2 - 8) ++ "px")
        , Html.Attributes.style "height" (String.fromInt (size2 - 8) ++ "px")
        , Html.Attributes.style "padding" "4px"
        , Html.Attributes.style "color" (MyUi.colorToStyle iconFontColor)
        ]
        [ Icons.person ]


iconView : Mode -> String -> Element msg
iconView mode url =
    Html.img
        [ Html.Attributes.style
            "width"
            (case mode of
                IsSelected ->
                    String.fromInt fullWidth ++ "px"

                _ ->
                    String.fromInt size ++ "px"
            )
        , Html.Attributes.style "height" (String.fromInt size ++ "px")
        , Html.Attributes.src url
        , Html.Attributes.style "display" "flex"
        , Html.Attributes.style "align-self" "center"
        , Html.Attributes.style "object-fit" "cover"
        , Html.Attributes.style
            "border-radius"
            (case mode of
                IsSelected ->
                    "0"

                _ ->
                    String.fromInt (round (toFloat size * 8 / 50)) ++ "px"
            )
        ]
        []
        |> Ui.html


{-| Font color for icons and initials drawn on top of the light colored
guild/user tiles
-}
iconFontColor : Ui.Color
iconFontColor =
    Ui.rgb 20 20 20


userDefaultColor : Id UserId -> Ui.Color
userDefaultColor userId =
    List.Nonempty.get (Id.toInt userId) userColors


userColors : Nonempty Ui.Color
userColors =
    Nonempty
        (Ui.rgb 232 134 170)
        [ Ui.rgb 235 179 142
        , Ui.rgb 232 215 139
        , Ui.rgb 188 244 155
        , Ui.rgb 172 246 228
        , Ui.rgb 198 150 232
        ]


size : number
size =
    50


fullWidth : number
fullWidth =
    58


addGuildButton : HtmlId -> Bool -> msg -> Element msg
addGuildButton htmlId isSelected onPress =
    MyUi.elButton
        htmlId
        onPress
        [ Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.centerX
        , if isSelected then
            Ui.noAttr

          else
            Ui.rounded (round (toFloat size * 8 / 50))
        , MyUi.notoSans
        , Ui.Font.weight 600
        , Ui.background MyUi.secondaryGray
        , Ui.border 1
        , Ui.borderColor MyUi.secondaryGrayBorder
        , if isSelected then
            Ui.width (Ui.px fullWidth)

          else
            Ui.width (Ui.px size)
        , Ui.height (Ui.px size)
        , Ui.padding 8
        , Ui.Font.color iconFontColor
        , MyUi.hoverText "Create new guild"
        ]
        (Ui.html Icons.plusIcon)


showFriendsButton : Bool -> msg -> Element msg
showFriendsButton isSelected onPress =
    MyUi.elButton
        (Dom.id "guildIcon_showFriends")
        onPress
        [ Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.centerX
        , if isSelected then
            Ui.noAttr

          else
            Ui.rounded (round (toFloat size * 8 / 50))
        , MyUi.notoSans
        , Ui.Font.weight 600
        , Ui.background MyUi.secondaryGray
        , Ui.border 1
        , Ui.borderColor MyUi.secondaryGrayBorder
        , if isSelected then
            Ui.width (Ui.px fullWidth)

          else
            Ui.width (Ui.px size)
        , Ui.height (Ui.px size)
        , Ui.padding 8
        , Ui.Font.color iconFontColor
        , MyUi.hoverText "Show friends list"
        ]
        (Ui.html Icons.userGroup)
