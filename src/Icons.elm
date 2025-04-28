module Icons exposing
    ( admin
    , close
    , collapseContainer
    , copy
    , copyIcon
    , delete
    , expandContainer
    , gearIcon
    , inviteUserIcon
    , link
    , logout
    , plusIcon
    , reset
    , signoutSvg
    , sortAscending
    , sortDescending
    , user
    , users
    )

import Html exposing (Html)
import Phosphor
import Svg
import Svg.Attributes
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


plusIcon : Html msg
plusIcon =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M12 5.25a.75.75 0 0 1 .75.75v5.25H18a.75.75 0 0 1 0 1.5h-5.25V18a.75.75 0 0 1-1.5 0v-5.25H6a.75.75 0 0 1 0-1.5h5.25V6a.75.75 0 0 1 .75-.75Z", Svg.Attributes.clipRule "evenodd" ] [] ]


gearIcon : Html msg
gearIcon =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z"
            ]
            []
        , Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
            ]
            []
        ]


inviteUserIcon : Html msg
inviteUserIcon =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.d "M5.25 6.375a4.125 4.125 0 1 1 8.25 0 4.125 4.125 0 0 1-8.25 0ZM2.25 19.125a7.125 7.125 0 0 1 14.25 0v.003l-.001.119a.75.75 0 0 1-.363.63 13.067 13.067 0 0 1-6.761 1.873c-2.472 0-4.786-.684-6.76-1.873a.75.75 0 0 1-.364-.63l-.001-.122ZM18.75 7.5a.75.75 0 0 0-1.5 0v2.25H15a.75.75 0 0 0 0 1.5h2.25v2.25a.75.75 0 0 0 1.5 0v-2.25H21a.75.75 0 0 0 0-1.5h-2.25V7.5Z" ] [] ]


copyIcon : Html msg
copyIcon =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.d "M7.5 3.375c0-1.036.84-1.875 1.875-1.875h.375a3.75 3.75 0 0 1 3.75 3.75v1.875C13.5 8.161 14.34 9 15.375 9h1.875A3.75 3.75 0 0 1 21 12.75v3.375C21 17.16 20.16 18 19.125 18h-9.75A1.875 1.875 0 0 1 7.5 16.125V3.375Z" ] [], Svg.path [ Svg.Attributes.d "M15 5.25a5.23 5.23 0 0 0-1.279-3.434 9.768 9.768 0 0 1 6.963 6.963A5.23 5.23 0 0 0 17.25 7.5h-1.875A.375.375 0 0 1 15 7.125V5.25ZM4.875 6H6v10.125A3.375 3.375 0 0 0 9.375 19.5H16.5v1.125c0 1.035-.84 1.875-1.875 1.875h-9.75A1.875 1.875 0 0 1 3 20.625V7.875C3 6.839 3.84 6 4.875 6Z" ] [] ]


signoutSvg : Html msg
signoutSvg =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M7.5 3.75A1.5 1.5 0 0 0 6 5.25v13.5a1.5 1.5 0 0 0 1.5 1.5h6a1.5 1.5 0 0 0 1.5-1.5V15a.75.75 0 0 1 1.5 0v3.75a3 3 0 0 1-3 3h-6a3 3 0 0 1-3-3V5.25a3 3 0 0 1 3-3h6a3 3 0 0 1 3 3V9A.75.75 0 0 1 15 9V5.25a1.5 1.5 0 0 0-1.5-1.5h-6Zm5.03 4.72a.75.75 0 0 1 0 1.06l-1.72 1.72h10.94a.75.75 0 0 1 0 1.5H10.81l1.72 1.72a.75.75 0 1 1-1.06 1.06l-3-3a.75.75 0 0 1 0-1.06l3-3a.75.75 0 0 1 1.06 0Z", Svg.Attributes.clipRule "evenodd" ] [] ]


users : Html msg
users =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M8.25 6.75a3.75 3.75 0 1 1 7.5 0 3.75 3.75 0 0 1-7.5 0ZM15.75 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0ZM2.25 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0ZM6.31 15.117A6.745 6.745 0 0 1 12 12a6.745 6.745 0 0 1 6.709 7.498.75.75 0 0 1-.372.568A12.696 12.696 0 0 1 12 21.75c-2.305 0-4.47-.612-6.337-1.684a.75.75 0 0 1-.372-.568 6.787 6.787 0 0 1 1.019-4.38Z", Svg.Attributes.clipRule "evenodd" ] [], Svg.path [ Svg.Attributes.d "M5.082 14.254a8.287 8.287 0 0 0-1.308 5.135 9.687 9.687 0 0 1-1.764-.44l-.115-.04a.563.563 0 0 1-.373-.487l-.01-.121a3.75 3.75 0 0 1 3.57-4.047ZM20.226 19.389a8.287 8.287 0 0 0-1.308-5.135 3.75 3.75 0 0 1 3.57 4.047l-.01.121a.563.563 0 0 1-.373.486l-.115.04c-.567.2-1.156.349-1.764.441Z" ] [] ]
