module Icons exposing
    ( admin
    , close
    , collapseContainer
    , copy
    , delete
    , expandContainer
    , link
    , logout
    , reset
    , sortAscending
    , sortDescending
    , user
    )

import Phosphor
import Ui


reset : Ui.Element msg
reset =
    Phosphor.arrowCounterClockwise Phosphor.Regular |> icon


logout : Ui.Element msg
logout =
    Phosphor.signOut Phosphor.Regular |> icon


admin : Ui.Element msg
admin =
    Phosphor.wrench Phosphor.Regular |> icon


link : Ui.Element msg
link =
    Phosphor.linkSimple Phosphor.Regular |> icon


sortAscending : Ui.Element msg
sortAscending =
    Phosphor.arrowFatDown Phosphor.Regular |> icon


sortDescending : Ui.Element msg
sortDescending =
    Phosphor.arrowFatUp Phosphor.Regular |> icon


collapseContainer : Ui.Element msg
collapseContainer =
    Phosphor.minusSquare Phosphor.Regular |> icon


expandContainer : Ui.Element msg
expandContainer =
    Phosphor.plusSquare Phosphor.Regular |> icon


delete : Ui.Element msg
delete =
    Phosphor.trash Phosphor.Bold |> icon


close : Ui.Element msg
close =
    Phosphor.x Phosphor.Bold |> icon


icon : Phosphor.IconVariant -> Ui.Element msg
icon i =
    i |> Phosphor.toHtml [] |> Ui.html


copy : Ui.Element msg
copy =
    Phosphor.copy Phosphor.Regular |> icon


user : Ui.Element msg
user =
    Phosphor.user Phosphor.Regular |> icon
