module GuildIcon exposing
    ( Mode(..)
    , NotificationType(..)
    , addGuildButton
    , notificationView
    , showFriendsButton
    , view
    )

import FileStatus
import GuildName
import Icons
import Image
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

            _ ->
                sidePadding
        , case mode of
            IsSelected ->
                Ui.noAttr

            Normal notification ->
                notificationView MyUi.background1 notification
        ]
        (case guild.icon of
            Just icon ->
                Ui.image
                    [ case mode of
                        IsSelected ->
                            Ui.noAttr

                        _ ->
                            Ui.width (Ui.px size)
                    , Ui.height (Ui.px size)
                    , case mode of
                        IsSelected ->
                            Ui.noAttr

                        _ ->
                            Ui.rounded (round (toFloat size * 8 / 50))
                    , Ui.clip
                    , Ui.border 1
                    , Ui.borderColor MyUi.secondaryGrayBorder
                    , MyUi.hoverText name
                    ]
                    { source = FileStatus.fileUrl FileStatus.pngContent icon
                    , description = name
                    , onLoad = Nothing
                    }

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
                        , Ui.height Ui.fill
                        , Ui.background (Ui.rgb 240 240 240)
                        , Ui.border 1
                        , Ui.borderColor MyUi.secondaryGrayBorder
                        , case mode of
                            IsSelected ->
                                Ui.noAttr

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


sidePadding : Ui.Attribute msg
sidePadding =
    Ui.paddingXY 4 0


addGuildButton : Bool -> msg -> Element msg
addGuildButton isSelected onPress =
    Ui.el
        [ if isSelected then
            Ui.noAttr

          else
            sidePadding
        ]
        (Ui.el
            [ Ui.contentCenterX
            , Ui.contentCenterY
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
                Ui.noAttr

              else
                Ui.width (Ui.px size)
            , Ui.height (Ui.px size)
            , Ui.padding 8
            , Ui.Font.color (Ui.rgb 20 20 20)
            , Ui.Input.button onPress
            , MyUi.hoverText "Create new guild"
            ]
            (Ui.html Icons.plusIcon)
        )


showFriendsButton : Bool -> msg -> Element msg
showFriendsButton isSelected onPress =
    Ui.el
        [ if isSelected then
            Ui.noAttr

          else
            sidePadding
        ]
        (Ui.el
            [ Ui.contentCenterX
            , Ui.contentCenterY
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
                Ui.noAttr

              else
                Ui.width (Ui.px size)
            , Ui.height (Ui.px size)
            , Ui.padding 8
            , Ui.Font.color (Ui.rgb 20 20 20)
            , Ui.Input.button onPress
            , MyUi.hoverText "Show friends list"
            ]
            (Ui.html Icons.users)
        )
