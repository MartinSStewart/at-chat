module GuildIcon exposing (size, view)

import GuildName
import Image
import LocalState exposing (Guild)
import MyUi
import Ui exposing (Element)
import Ui.Font
import Ui.Shadow


view : Bool -> Guild -> Element msg
view isSelected portfolio =
    case portfolio.icon of
        Just icon ->
            Ui.image
                [ Ui.width (Ui.px size)
                , Ui.height (Ui.px size)
                , Ui.rounded 8
                , Ui.clip
                , Ui.border 1
                , Ui.borderColor MyUi.secondaryGrayBorder
                ]
                { source = Image.url icon
                , description = GuildName.toString portfolio.name
                , onLoad = Nothing
                }

        Nothing ->
            GuildName.toString portfolio.name
                |> String.replace "-" " "
                |> String.filter (\char -> Char.isAlphaNum char || char == ' ')
                |> String.words
                |> List.take 3
                |> List.map (String.left 1)
                |> String.concat
                |> Ui.text
                |> Ui.el
                    [ Ui.contentCenterX
                    , Ui.contentCenterY
                    , Ui.rounded 8
                    , MyUi.montserrat
                    , Ui.Font.weight 600
                    , Ui.height Ui.fill
                    , Ui.background (Ui.rgb 240 240 240)
                    , Ui.border 1
                    , Ui.borderColor MyUi.secondaryGrayBorder
                    , Ui.width (Ui.px size)
                    , Ui.height (Ui.px size)
                    , Ui.Font.size 18
                    ]


size : number
size =
    50
