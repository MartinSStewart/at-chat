module GuildIcon exposing
    ( Mode(..)
    , NotificationType(..)
    , addGuildButton
    , fullWidth
    , notificationView
    , showFriendsButton
    , view
    )

import FileStatus
import GuildName
import Html
import Html.Attributes
import Icons
import LocalState exposing (FrontendGuild)
import MyUi
import Ui exposing (Element)
import Ui.Font
import Ui.Input


type Mode
    = Normal NotificationType
    | IsSelected


type NotificationType
    = NoNotification
    | NewMessage
    | NewMessageForUser


notificationView : Ui.Color -> NotificationType -> Ui.Attribute msg
notificationView borderColor notification =
    case notification of
        NoNotification ->
            Ui.noAttr

        NewMessage ->
            Ui.inFront
                (Ui.el
                    [ Ui.rounded 99
                    , Ui.background (Ui.rgb 255 255 255)
                    , Ui.width (Ui.px 14)
                    , Ui.height (Ui.px 14)
                    , Ui.border 2
                    , Ui.borderColor borderColor
                    , Ui.move { x = 0, y = -3, z = 0 }
                    , Ui.alignRight
                    ]
                    Ui.none
                )

        NewMessageForUser ->
            Ui.inFront
                (Ui.el
                    [ Ui.rounded 99
                    , Ui.background MyUi.alertColor
                    , Ui.width (Ui.px 14)
                    , Ui.height (Ui.px 14)
                    , Ui.border 2
                    , Ui.borderColor borderColor
                    , Ui.move { x = 0, y = -3, z = 0 }
                    , Ui.alignRight
                    ]
                    Ui.none
                )


view : Mode -> FrontendGuild -> Element msg
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
                notificationView MyUi.background1 notification
        ]
        (case guild.icon of
            Just icon ->
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


size : number
size =
    50


fullWidth : number
fullWidth =
    58


addGuildButton : Bool -> msg -> Element msg
addGuildButton isSelected onPress =
    Ui.el
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
        , Ui.Input.button onPress
        , MyUi.hoverText "Create new guild"
        ]
        (Ui.html Icons.plusIcon)


showFriendsButton : Bool -> msg -> Element msg
showFriendsButton isSelected onPress =
    Ui.el
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
        , Ui.Input.button onPress
        , MyUi.hoverText "Show friends list"
        ]
        (Ui.html Icons.users)
