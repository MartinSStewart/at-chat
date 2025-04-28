module GuildIcon exposing (addGuildButton, showFriendsButton, view)

import GuildName exposing (GuildName)
import Icons
import Image exposing (Image)
import LocalState exposing (BackendGuild, FrontendGuild)
import MyUi
import Ui exposing (Element)
import Ui.Font
import Ui.Input


view : Bool -> Int -> FrontendGuild -> Element msg
view isSelected size guild =
    let
        name =
            GuildName.toString guild.name
    in
    case guild.icon of
        Just icon ->
            Ui.image
                [ Ui.width (Ui.px size)
                , Ui.height (Ui.px size)
                , Ui.rounded 8
                , Ui.clip
                , Ui.border 1
                , Ui.borderColor MyUi.secondaryGrayBorder
                , MyUi.hoverText name
                ]
                { source = Image.url icon
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
                    , Ui.rounded (round (toFloat size * 8 / 50))
                    , MyUi.montserrat
                    , Ui.Font.weight 600
                    , Ui.height Ui.fill
                    , Ui.background (Ui.rgb 240 240 240)
                    , Ui.border 1
                    , Ui.borderColor MyUi.secondaryGrayBorder
                    , Ui.width (Ui.px size)
                    , Ui.height (Ui.px size)
                    , Ui.Font.size (round (toFloat size * 18 / 50))
                    , Ui.Font.color (Ui.rgb 20 20 20)
                    , MyUi.hoverText name
                    ]


addGuildButton : msg -> Element msg
addGuildButton onPress =
    let
        size =
            50
    in
    Ui.el
        [ Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.rounded (round (toFloat size * 8 / 50))
        , MyUi.montserrat
        , Ui.Font.weight 600
        , Ui.height Ui.fill
        , Ui.background (Ui.rgb 240 240 240)
        , Ui.border 1
        , Ui.borderColor MyUi.secondaryGrayBorder
        , Ui.width (Ui.px size)
        , Ui.height (Ui.px size)
        , Ui.padding 8
        , Ui.Font.color (Ui.rgb 20 20 20)
        , Ui.Input.button onPress
        , MyUi.hoverText "Create new guild"
        ]
        (Ui.html Icons.plusIcon)


showFriendsButton : msg -> Element msg
showFriendsButton onPress =
    let
        size =
            50
    in
    Ui.el
        [ Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.rounded (round (toFloat size * 8 / 50))
        , MyUi.montserrat
        , Ui.Font.weight 600
        , Ui.height Ui.fill
        , Ui.background (Ui.rgb 240 240 240)
        , Ui.border 1
        , Ui.borderColor MyUi.secondaryGrayBorder
        , Ui.width (Ui.px size)
        , Ui.height (Ui.px size)
        , Ui.padding 8
        , Ui.Font.color (Ui.rgb 20 20 20)
        , Ui.Input.button onPress
        , MyUi.hoverText "Show friends list"
        ]
        (Ui.html Icons.users)
