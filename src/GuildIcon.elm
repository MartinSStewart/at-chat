module GuildIcon exposing
    ( ChannelNotificationType(..)
    , Mode(..)
    , addGuildButton
    , fullWidth
    , notificationView
    , showFriendsButton
    , userView
    , view
    )

import Effect.Browser.Dom as Dom exposing (HtmlId)
import FileStatus
import GuildName
import Html
import Html.Attributes
import Icons
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (FrontendGuild)
import MyUi
import OneOrGreater exposing (OneOrGreater)
import Ui exposing (Element)
import Ui.Font
import UserAgent exposing (Browser(..), UserAgent)


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


notificationHelper : UserAgent -> Ui.Color -> Ui.Color -> Ui.Color -> Int -> Int -> OneOrGreater -> Ui.Attribute msg
notificationHelper userAgent color fontColor borderColor xOffset yOffset count =
    let
        count2 : Int
        count2 =
            OneOrGreater.toInt count
    in
    Ui.inFront
        (Ui.el
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
            , Ui.Font.lineHeight 1
            , Ui.Font.size
                (if count2 > maxNotifications then
                    13

                 else
                    11
                )
            , Ui.Font.bold
            , Ui.Font.color fontColor
            , Ui.Font.family [ Ui.Font.typeface "Arial" ]
            ]
            (Ui.el
                [ Ui.contentCenterX
                , Ui.move
                    (case userAgent.browser of
                        Safari ->
                            { x = 0
                            , y =
                                if count2 > maxNotifications then
                                    0

                                else
                                    1
                            , z = 0
                            }

                        Firefox ->
                            { x = 0
                            , y =
                                if count2 > maxNotifications then
                                    -1

                                else
                                    1
                            , z = 0
                            }

                        _ ->
                            { x = 0
                            , y =
                                if count2 > maxNotifications then
                                    -2

                                else
                                    0
                            , z = 0
                            }
                    )
                ]
                (Ui.text
                    (if count2 > maxNotifications then
                        "∞"

                     else
                        String.fromInt count2
                    )
                )
            )
        )


notificationView : UserAgent -> Int -> Int -> Ui.Color -> ChannelNotificationType -> Ui.Attribute msg
notificationView userAgent xOffset yOffset borderColor notification =
    case notification of
        NoNotification ->
            Ui.noAttr

        NewMessage count ->
            notificationHelper userAgent MyUi.white (Ui.rgb 0 0 0) borderColor xOffset yOffset count

        NewMessageForUser count ->
            notificationHelper userAgent MyUi.alertColor MyUi.white borderColor xOffset yOffset count


view : UserAgent -> Mode -> FrontendGuild channelId -> Element msg
view userAgent mode guild =
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
                notificationView userAgent 0 -3 MyUi.background1 notification
        ]
        (case guild.icon of
            Just icon ->
                iconView mode icon

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
                        , MyUi.montserrat
                        , Ui.Font.weight 600
                        , Ui.background (Ui.rgb 240 240 240)
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
                        , Ui.Font.color (Ui.rgb 20 20 20)
                        , MyUi.hoverText name
                        ]
        )


userView : UserAgent -> ChannelNotificationType -> Maybe FileStatus.FileHash -> Id UserId -> Element msg
userView userAgent notification maybeIcon userId =
    Ui.el
        [ notificationView userAgent 0 -3 MyUi.background1 notification
        ]
        (case maybeIcon of
            Just icon ->
                iconView (Normal notification) icon

            Nothing ->
                Ui.el
                    [ Ui.contentCenterX
                    , Ui.contentCenterY
                    , Ui.rounded (round (toFloat size * 8 / 50))
                    , MyUi.montserrat
                    , Ui.Font.weight 600
                    , Ui.background (userDefaultColor userId)
                    , Ui.centerX
                    , Ui.width (Ui.px size)
                    , Ui.height (Ui.px size)
                    , Ui.Font.size (round (toFloat size * 18 / 50))
                    , Ui.Font.color (Ui.rgb 20 20 20)
                    , Ui.paddingXY 4 0
                    ]
                    (Ui.html Icons.person)
        )


iconView : Mode -> FileStatus.FileHash -> Element msg
iconView mode icon =
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
        , Html.Attributes.src (FileStatus.fileUrl FileStatus.pngContent icon)
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
        , MyUi.montserrat
        , Ui.Font.weight 600
        , Ui.height Ui.fill
        , Ui.background (Ui.rgb 240 240 240)
        , Ui.border 1
        , Ui.borderColor MyUi.secondaryGrayBorder
        , if isSelected then
            Ui.width (Ui.px fullWidth)

          else
            Ui.width (Ui.px size)
        , Ui.height (Ui.px size)
        , Ui.padding 8
        , Ui.Font.color (Ui.rgb 20 20 20)
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
        , MyUi.montserrat
        , Ui.Font.weight 600
        , Ui.height Ui.fill
        , Ui.background (Ui.rgb 240 240 240)
        , Ui.border 1
        , Ui.borderColor MyUi.secondaryGrayBorder
        , if isSelected then
            Ui.width (Ui.px fullWidth)

          else
            Ui.width (Ui.px size)
        , Ui.height (Ui.px size)
        , Ui.padding 8
        , Ui.Font.color (Ui.rgb 20 20 20)
        , MyUi.hoverText "Show friends list"
        ]
        (Ui.html Icons.userGroup)
