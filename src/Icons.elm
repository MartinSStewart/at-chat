module Icons exposing
    ( addApp
    , arrowLeft
    , attachment
    , checkmark
    , closedEye
    , collapseContainer
    , copy
    , copyIcon
    , delete
    , document
    , dotDotDot
    , download
    , expandContainer
    , gear
    , hashtag
    , inviteUserIcon
    , link
    , logoutSvg
    , openEye
    , pencil
    , plusIcon
    , reply
    , reset
    , sendMessage
    , smile
    , sortAscending
    , sortDescending
    , threadBottomSegment
    , threadMiddleSegment
    , threadSingleSegment
    , threadTopSegment
    , users
    , x
    )

import Html exposing (Html)
import Phosphor
import Svg exposing (Svg)
import Svg.Attributes
import Ui


reset : Ui.Element msg
reset =
    Phosphor.arrowCounterClockwise Phosphor.Regular |> icon


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


delete : Html msg
delete =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "24"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"
            ]
            []
        ]


download : Html msg
download =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "18"
        ]
        [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" ] [] ]


icon : Phosphor.IconVariant -> Ui.Element msg
icon i =
    i |> Phosphor.toHtml [] |> Ui.html


copy : Ui.Element msg
copy =
    Phosphor.copy Phosphor.Regular |> icon


plusIcon : Html msg
plusIcon =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M12 5.25a.75.75 0 0 1 .75.75v5.25H18a.75.75 0 0 1 0 1.5h-5.25V18a.75.75 0 0 1-1.5 0v-5.25H6a.75.75 0 0 1 0-1.5h5.25V6a.75.75 0 0 1 .75-.75Z", Svg.Attributes.clipRule "evenodd" ] [] ]


gear : Html msg
gear =
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


logoutSvg : Html msg
logoutSvg =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M7.5 3.75A1.5 1.5 0 0 0 6 5.25v13.5a1.5 1.5 0 0 0 1.5 1.5h6a1.5 1.5 0 0 0 1.5-1.5V15a.75.75 0 0 1 1.5 0v3.75a3 3 0 0 1-3 3h-6a3 3 0 0 1-3-3V5.25a3 3 0 0 1 3-3h6a3 3 0 0 1 3 3V9A.75.75 0 0 1 15 9V5.25a1.5 1.5 0 0 0-1.5-1.5h-6Zm5.03 4.72a.75.75 0 0 1 0 1.06l-1.72 1.72h10.94a.75.75 0 0 1 0 1.5H10.81l1.72 1.72a.75.75 0 1 1-1.06 1.06l-3-3a.75.75 0 0 1 0-1.06l3-3a.75.75 0 0 1 1.06 0Z", Svg.Attributes.clipRule "evenodd" ] [] ]


users : Html msg
users =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.width "32", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M8.25 6.75a3.75 3.75 0 1 1 7.5 0 3.75 3.75 0 0 1-7.5 0ZM15.75 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0ZM2.25 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0ZM6.31 15.117A6.745 6.745 0 0 1 12 12a6.745 6.745 0 0 1 6.709 7.498.75.75 0 0 1-.372.568A12.696 12.696 0 0 1 12 21.75c-2.305 0-4.47-.612-6.337-1.684a.75.75 0 0 1-.372-.568 6.787 6.787 0 0 1 1.019-4.38Z", Svg.Attributes.clipRule "evenodd" ] [], Svg.path [ Svg.Attributes.d "M5.082 14.254a8.287 8.287 0 0 0-1.308 5.135 9.687 9.687 0 0 1-1.764-.44l-.115-.04a.563.563 0 0 1-.373-.487l-.01-.121a3.75 3.75 0 0 1 3.57-4.047ZM20.226 19.389a8.287 8.287 0 0 0-1.308-5.135 3.75 3.75 0 0 1 3.57 4.047l-.01.121a.563.563 0 0 1-.373.486l-.115.04c-.567.2-1.156.349-1.764.441Z" ] [] ]


smile : Html msg
smile =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25Zm-2.625 6c-.54 0-.828.419-.936.634a1.96 1.96 0 0 0-.189.866c0 .298.059.605.189.866.108.215.395.634.936.634.54 0 .828-.419.936-.634.13-.26.189-.568.189-.866 0-.298-.059-.605-.189-.866-.108-.215-.395-.634-.936-.634Zm4.314.634c.108-.215.395-.634.936-.634.54 0 .828.419.936.634.13.26.189.568.189.866 0 .298-.059.605-.189.866-.108.215-.395.634-.936.634-.54 0-.828-.419-.936-.634a1.96 1.96 0 0 1-.189-.866c0-.298.059-.605.189-.866Zm2.023 6.828a.75.75 0 1 0-1.06-1.06 3.75 3.75 0 0 1-5.304 0 .75.75 0 0 0-1.06 1.06 5.25 5.25 0 0 0 7.424 0Z", Svg.Attributes.clipRule "evenodd" ] [] ]


pencil : Html msg
pencil =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.d "M21.731 2.269a2.625 2.625 0 0 0-3.712 0l-1.157 1.157 3.712 3.712 1.157-1.157a2.625 2.625 0 0 0 0-3.712ZM19.513 8.199l-3.712-3.712-12.15 12.15a5.25 5.25 0 0 0-1.32 2.214l-.8 2.685a.75.75 0 0 0 .933.933l2.685-.8a5.25 5.25 0 0 0 2.214-1.32L19.513 8.2Z" ] [] ]


reply : Html msg
reply =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "m16.49 12 3.75-3.751m0 0-3.75-3.75m3.75 3.75H3.74V19.5" ] [] ]


x : Html msg
x =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.width "24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "M6 18 18 6M6 6l12 12" ] [] ]


hashtag : Html msg
hashtag =
    Svg.svg [ Svg.Attributes.width "20", Svg.Attributes.viewBox "0 0 16 16", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M7.487 2.89a.75.75 0 1 0-1.474-.28l-.455 2.388H3.61a.75.75 0 0 0 0 1.5h1.663l-.571 2.998H2.75a.75.75 0 0 0 0 1.5h1.666l-.403 2.114a.75.75 0 0 0 1.474.28l.456-2.394h2.973l-.403 2.114a.75.75 0 0 0 1.474.28l.456-2.394h1.947a.75.75 0 0 0 0-1.5h-1.661l.57-2.998h1.95a.75.75 0 0 0 0-1.5h-1.664l.402-2.108a.75.75 0 0 0-1.474-.28l-.455 2.388H7.085l.402-2.108ZM6.8 6.498l-.571 2.998h2.973l.57-2.998H6.8Z", Svg.Attributes.clipRule "evenodd" ] [] ]


arrowLeft : Html msg
arrowLeft =
    Svg.svg [ Svg.Attributes.viewBox "0 0 16 16", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M14 8a.75.75 0 0 1-.75.75H4.56l3.22 3.22a.75.75 0 1 1-1.06 1.06l-4.5-4.5a.75.75 0 0 1 0-1.06l4.5-4.5a.75.75 0 0 1 1.06 1.06L4.56 7.25h8.69A.75.75 0 0 1 14 8Z", Svg.Attributes.clipRule "evenodd" ] [] ]


sendMessage : Html msg
sendMessage =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "24"
        ]
        [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "M6 12 3.269 3.125A59.769 59.769 0 0 1 21.485 12 59.768 59.768 0 0 1 3.27 20.875L5.999 12Zm0 0h7.5" ] [] ]


dotDotDot : Html msg
dotDotDot =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M6.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM12.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM18.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z"
            ]
            []
        ]


addApp : Html msg
addApp =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "M13.5 16.875h3.375m0 0h3.375m-3.375 0V13.5m0 3.375v3.375M6 10.5h2.25a2.25 2.25 0 0 0 2.25-2.25V6a2.25 2.25 0 0 0-2.25-2.25H6A2.25 2.25 0 0 0 3.75 6v2.25A2.25 2.25 0 0 0 6 10.5Zm0 9.75h2.25A2.25 2.25 0 0 0 10.5 18v-2.25a2.25 2.25 0 0 0-2.25-2.25H6a2.25 2.25 0 0 0-2.25 2.25V18A2.25 2.25 0 0 0 6 20.25Zm9.75-9.75H18a2.25 2.25 0 0 0 2.25-2.25V6A2.25 2.25 0 0 0 18 3.75h-2.25A2.25 2.25 0 0 0 13.5 6v2.25a2.25 2.25 0 0 0 2.25 2.25Z" ] [] ]


checkmark : Html msg
checkmark =
    Svg.svg [ Svg.Attributes.viewBox "0 0 20 20", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M16.704 4.153a.75.75 0 0 1 .143 1.052l-8 10.5a.75.75 0 0 1-1.127.075l-4.5-4.5a.75.75 0 0 1 1.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 0 1 1.05-.143Z", Svg.Attributes.clipRule "evenodd" ] [] ]


attachment : Html msg
attachment =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "24"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "m18.375 12.739-7.693 7.693a4.5 4.5 0 0 1-6.364-6.364l10.94-10.94A3 3 0 1 1 19.5 7.372L8.552 18.32m.009-.01-.01.01m5.699-9.941-7.81 7.81a1.5 1.5 0 0 0 2.112 2.13"
            ]
            []
        ]


document : Html msg
document =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"
            ]
            []
        ]


openEye : Html msg
openEye =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "24"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z"
            ]
            []
        , Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
            ]
            []
        ]


closedEye : Html msg
closedEye =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "24"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.451 10.451 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.522 10.522 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.228-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88"
            ]
            []
        ]


threadTopSegment : Svg msg
threadTopSegment =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 20 38"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "20"
        ]
        [ Svg.g []
            [ Svg.line
                [ Svg.Attributes.y2 "38"
                , Svg.Attributes.x2 "10"
                , Svg.Attributes.y1 "4"
                , Svg.Attributes.x1 "10"
                ]
                []
            , Svg.line
                [ Svg.Attributes.y2 "19"
                , Svg.Attributes.x2 "10"
                , Svg.Attributes.y1 "19"
                , Svg.Attributes.x1 "20"
                ]
                []
            ]
        ]


threadMiddleSegment : Svg msg
threadMiddleSegment =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 20 38"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "20"
        ]
        [ Svg.g []
            [ Svg.line
                [ Svg.Attributes.y2 "38"
                , Svg.Attributes.x2 "10"
                , Svg.Attributes.y1 "0"
                , Svg.Attributes.x1 "10"
                ]
                []
            , Svg.line
                [ Svg.Attributes.y2 "19"
                , Svg.Attributes.x2 "10"
                , Svg.Attributes.y1 "19"
                , Svg.Attributes.x1 "20"
                ]
                []
            ]
        ]


threadBottomSegment : Svg msg
threadBottomSegment =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 20 38"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "20"
        ]
        [ Svg.g []
            [ Svg.line
                [ Svg.Attributes.y2 "20.75"
                , Svg.Attributes.x2 "10"
                , Svg.Attributes.y1 "0"
                , Svg.Attributes.x1 "10"
                ]
                []
            , Svg.line
                [ Svg.Attributes.y2 "20"
                , Svg.Attributes.x2 "10"
                , Svg.Attributes.y1 "20"
                , Svg.Attributes.x1 "20"
                ]
                []
            ]
        ]


threadSingleSegment : Svg msg
threadSingleSegment =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 20 38"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "20"
        ]
        [ Svg.g []
            [ Svg.line
                [ Svg.Attributes.y2 "20.75"
                , Svg.Attributes.x2 "10"
                , Svg.Attributes.y1 "4"
                , Svg.Attributes.x1 "10"
                ]
                []
            , Svg.line
                [ Svg.Attributes.y2 "20"
                , Svg.Attributes.x2 "10"
                , Svg.Attributes.y1 "20"
                , Svg.Attributes.x1 "20"
                ]
                []
            ]
        ]
