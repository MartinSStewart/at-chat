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
    , desktop
    , discord
    , document
    , dotDotDot
    , download
    , expandContainer
    , gear
    , hashtag
    , image
    , infinity
    , info
    , inviteUserIcon
    , link
    , logoutSvg
    , map
    , mobile
    , number
    , numbers
    , openEye
    , pencil
    , person
    , phone
    , plusIcon
    , reply
    , reset
    , sendMessage
    , smile
    , sortAscending
    , sortDescending
    , spinner
    , tablet
    , threadBottomSegment
    , threadMiddleSegment
    , threadSingleSegment
    , threadTopSegment
    , userGroup
    , users
    , warning
    , x
    )

import Html exposing (Html)
import Html.Attributes
import Svg exposing (Svg)
import Svg.Attributes
import Ui
import Ui.Anim


reset : Ui.Element msg
reset =
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
            , Svg.Attributes.d "M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
            ]
            []
        ]
        |> Ui.html


link : Ui.Element msg
link =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "20"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244"
            ]
            []
        ]
        |> Ui.html


sortAscending : Ui.Element msg
sortAscending =
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
            , Svg.Attributes.d "m19.5 8.25-7.5 7.5-7.5-7.5"
            ]
            []
        ]
        |> Ui.html


sortDescending : Ui.Element msg
sortDescending =
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
            , Svg.Attributes.d "m4.5 15.75 7.5-7.5 7.5 7.5"
            ]
            []
        ]
        |> Ui.html


collapseContainer : Ui.Element msg
collapseContainer =
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
            , Svg.Attributes.d "M15 12H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
            ]
            []
        ]
        |> Ui.html


expandContainer : Ui.Element msg
expandContainer =
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
            , Svg.Attributes.d "M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
            ]
            []
        ]
        |> Ui.html


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


copy : Html msg
copy =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width "22"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 0 1-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 0 1 1.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 0 0-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 0 1-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 0 0-3.375-3.375h-1.5a1.125 1.125 0 0 1-1.125-1.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H9.75"
            ]
            []
        ]


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


userGroup : Html msg
userGroup =
    Svg.svg [ Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.width "32", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M8.25 6.75a3.75 3.75 0 1 1 7.5 0 3.75 3.75 0 0 1-7.5 0ZM15.75 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0ZM2.25 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0ZM6.31 15.117A6.745 6.745 0 0 1 12 12a6.745 6.745 0 0 1 6.709 7.498.75.75 0 0 1-.372.568A12.696 12.696 0 0 1 12 21.75c-2.305 0-4.47-.612-6.337-1.684a.75.75 0 0 1-.372-.568 6.787 6.787 0 0 1 1.019-4.38Z", Svg.Attributes.clipRule "evenodd" ] [], Svg.path [ Svg.Attributes.d "M5.082 14.254a8.287 8.287 0 0 0-1.308 5.135 9.687 9.687 0 0 1-1.764-.44l-.115-.04a.563.563 0 0 1-.373-.487l-.01-.121a3.75 3.75 0 0 1 3.57-4.047ZM20.226 19.389a8.287 8.287 0 0 0-1.308-5.135 3.75 3.75 0 0 1 3.57 4.047l-.01.121a.563.563 0 0 1-.373.486l-.115.04c-.567.2-1.156.349-1.764.441Z" ] [] ]


users : Html msg
users =
    Svg.svg
        [ Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.fill "currentColor"
        ]
        [ Svg.path [ Svg.Attributes.d "M4.5 6.375a4.125 4.125 0 1 1 8.25 0 4.125 4.125 0 0 1-8.25 0ZM14.25 8.625a3.375 3.375 0 1 1 6.75 0 3.375 3.375 0 0 1-6.75 0ZM1.5 19.125a7.125 7.125 0 0 1 14.25 0v.003l-.001.119a.75.75 0 0 1-.363.63 13.067 13.067 0 0 1-6.761 1.873c-2.472 0-4.786-.684-6.76-1.873a.75.75 0 0 1-.364-.63l-.001-.122ZM17.25 19.128l-.001.144a2.25 2.25 0 0 1-.233.96 10.088 10.088 0 0 0 5.06-1.01.75.75 0 0 0 .42-.643 4.875 4.875 0 0 0-6.957-4.611 8.586 8.586 0 0 1 1.71 5.157v.003Z" ] [] ]


smile : Html msg
smile =
    Svg.svg
        [ Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.fill "currentColor"
        , Svg.Attributes.width "24"
        ]
        [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25Zm-2.625 6c-.54 0-.828.419-.936.634a1.96 1.96 0 0 0-.189.866c0 .298.059.605.189.866.108.215.395.634.936.634.54 0 .828-.419.936-.634.13-.26.189-.568.189-.866 0-.298-.059-.605-.189-.866-.108-.215-.395-.634-.936-.634Zm4.314.634c.108-.215.395-.634.936-.634.54 0 .828.419.936.634.13.26.189.568.189.866 0 .298-.059.605-.189.866-.108.215-.395.634-.936.634-.54 0-.828-.419-.936-.634a1.96 1.96 0 0 1-.189-.866c0-.298.059-.605.189-.866Zm2.023 6.828a.75.75 0 1 0-1.06-1.06 3.75 3.75 0 0 1-5.304 0 .75.75 0 0 0-1.06 1.06 5.25 5.25 0 0 0 7.424 0Z", Svg.Attributes.clipRule "evenodd" ] [] ]


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


person : Html msg
person =
    Svg.svg
        [ Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.fill "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.fillRule "evenodd"
            , Svg.Attributes.d "M7.5 6a4.5 4.5 0 1 1 9 0 4.5 4.5 0 0 1-9 0ZM3.751 20.105a8.25 8.25 0 0 1 16.498 0 .75.75 0 0 1-.437.695A18.683 18.683 0 0 1 12 22.5c-2.786 0-5.433-.608-7.812-1.7a.75.75 0 0 1-.437-.695Z"
            , Svg.Attributes.clipRule "evenodd"
            ]
            []
        ]


image : Html msg
image =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 4 24 16"
        , Svg.Attributes.width "18"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"
            ]
            []
        ]


info : Html msg
info =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"
            ]
            []
        ]


map : Html msg
map =
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
            , Svg.Attributes.d "M9 6.75V15m6-6v8.25m.503 3.498 4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 0 0-1.006 0L3.622 5.689C3.24 5.88 3 6.27 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0Z"
            ]
            []
        ]


mobile : Html msg
mobile =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M10.5 1.5H8.25A2.25 2.25 0 0 0 6 3.75v16.5a2.25 2.25 0 0 0 2.25 2.25h7.5A2.25 2.25 0 0 0 18 20.25V3.75a2.25 2.25 0 0 0-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3"
            ]
            []
        ]


tablet : Html msg
tablet =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M10.5 19.5h3m-6.75 2.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-15a2.25 2.25 0 0 0-2.25-2.25H6.75A2.25 2.25 0 0 0 4.5 4.5v15a2.25 2.25 0 0 0 2.25 2.25Z"
            ]
            []
        ]


desktop : Html msg
desktop =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M9 17.25v1.007a3 3 0 0 1-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0 1 15 18.257V17.25m6-12V15a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 15V5.25m18 0A2.25 2.25 0 0 0 18.75 3H5.25A2.25 2.25 0 0 0 3 5.25m18 0V12a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 12V5.25"
            ]
            []
        ]


discord : Html msg
discord =
    Svg.svg
        [ Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.fill "currentColor"
        , Svg.Attributes.width "12"
        ]
        [ Svg.path
            [ Svg.Attributes.d "M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"
            ]
            []
        ]


warning : Int -> Html msg
warning width =
    Svg.svg
        [ Svg.Attributes.fill "none"
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.strokeWidth "1.5"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            , Svg.Attributes.d "M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"
            ]
            []
        ]


spinner : Ui.Element msg
spinner =
    Ui.el
        [ Ui.width (Ui.px 16)
        , Ui.height (Ui.px 16)
        , Ui.Anim.spinning (Ui.Anim.ms 1000)
        , Ui.htmlAttribute (Html.Attributes.style "border-top-color" "transparent")
        , -- This line has to come after border-top-color for some reason
          Ui.htmlAttribute (Html.Attributes.style "border" "2px solid #fff")
        , Ui.htmlAttribute (Html.Attributes.style "border-radius" "50px")
        ]
        Ui.none


numbers : Int -> String -> List (Html msg)
numbers width value =
    numberHelper width [] (String.toList value)
        |> List.reverse


number : Int -> Char -> Html msg
number width char =
    case char of
        '0' ->
            zero width

        '1' ->
            one width

        '2' ->
            two width

        '3' ->
            three width

        '4' ->
            four width

        '5' ->
            five width

        '6' ->
            six width

        '7' ->
            seven width

        '8' ->
            eight width

        '9' ->
            nine width

        _ ->
            Html.span [ Html.Attributes.style "width" (String.fromInt width ++ "px") ] []


numberHelper : Int -> List (Html msg) -> List Char -> List (Html msg)
numberHelper width html int =
    case int of
        char :: rest ->
            numberHelper width (number width char :: html) rest

        [] ->
            html


zero : Int -> Html msg
zero width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.fillRule "evenodd"
            , Svg.Attributes.clipRule "evenodd"
            , Svg.Attributes.d "M3 5C3 2.23858 5.23858 0 8 0C10.7614 0 13 2.23858 13 5V11C13 13.7614 10.7614 16 8 16C5.23858 16 3 13.7614 3 11V5ZM8 3C6.89543 3 6 3.89543 6 5V11C6 12.1046 6.89543 13 8 13C9.10457 13 10 12.1046 10 11V5C10 3.89543 9.10457 3 8 3Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


one : Int -> Html msg
one width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.d "M6.64594 0L2.32922 2.15836L3.67086 4.84164L7.00004 3.17705V13H3.00004V16H13V13H10V0H6.64594Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


two : Int -> Html msg
two width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.d "M3 5C3 2.23858 5.23858 0 8 0H8.07519C10.7951 0 13 2.20491 13 4.92481C13 6.36248 12.3718 7.72838 11.2802 8.66401L6.22155 13H13V16H3V11.8101L9.32784 6.38624C9.75447 6.02056 10 5.48671 10 4.92481C10 3.86177 9.13823 3 8.07519 3H8C6.89543 3 6 3.89543 6 5H3Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


three : Int -> Html msg
three width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.d "M6.5 4.5C6.5 3.67157 7.17157 3 8 3C8.82843 3 9.5 3.67157 9.5 4.5C9.5 5.32843 8.82843 6 8 6H7V9H8C9.10457 9 10 9.89543 10 11C10 12.1046 9.10457 13 8 13C6.89543 13 6 12.1046 6 11H3C3 13.7614 5.23858 16 8 16C10.7614 16 13 13.7614 13 11C13 9.57824 12.4066 8.29508 11.4539 7.38469C12.107 6.60363 12.5 5.59771 12.5 4.5C12.5 2.01472 10.4853 0 8 0C5.51472 0 3.5 2.01472 3.5 4.5H6.5Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


four : Int -> Html msg
four width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.d "M13 0H10V7H6.03769L7.46324 0.680058L4.53676 0.0199507L3 6.83293V10H10V16H13V0Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


five : Int -> Html msg
five width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.d "M4.11984 0H13V3H6.88024L6.70068 5.15468C7.11748 5.05361 7.55269 5 8.00004 5C11.0376 5 13.5 7.46243 13.5 10.5C13.5 13.5376 11.0376 16 8.00004 16C5.68948 16 3.71518 14.5757 2.90039 12.5628L5.6812 11.4372C6.05319 12.3561 6.95322 13 8.00004 13C9.38075 13 10.5 11.8807 10.5 10.5C10.5 9.11929 9.38075 8 8.00004 8C7.36498 8 6.78843 8.23483 6.34681 8.62461L5.9215 9H3.36984L4.11984 0Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


six : Int -> Html msg
six width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.fillRule "evenodd"
            , Svg.Attributes.clipRule "evenodd"
            , Svg.Attributes.d "M8.14856 5.00197C11.1174 5.0807 13.5 7.51211 13.5 10.5C13.5 13.5376 11.0376 16 8 16C4.96243 16 2.5 13.5376 2.5 10.5C2.5 9.44185 2.79882 8.45349 3.31667 7.61471L7.43172 0.0343628L10.0683 1.46564L8.14856 5.00197ZM5.90352 9.13756C6.34947 8.45275 7.12186 8 8 8C9.38071 8 10.5 9.11929 10.5 10.5C10.5 11.8807 9.38071 13 8 13C6.61929 13 5.5 11.8807 5.5 10.5C5.5 10.0937 5.60153 9.69386 5.79537 9.33679L5.90352 9.13756Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


seven : Int -> Html msg
seven width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.d "M9.875 3H3V0H13V3.3L7.88462 15.5769L5.11538 14.4231L9.875 3Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


eight : Int -> Html msg
eight width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.fillRule "evenodd"
            , Svg.Attributes.clipRule "evenodd"
            , Svg.Attributes.d "M11.4539 7.38469C12.107 6.60363 12.5 5.59772 12.5 4.5C12.5 2.01472 10.4853 0 8 0C5.51472 0 3.5 2.01472 3.5 4.5C3.5 5.59771 3.89304 6.60363 4.54608 7.38469C3.59342 8.29508 3 9.57824 3 11C3 13.7614 5.23858 16 8 16C10.7614 16 13 13.7614 13 11C13 9.57824 12.4066 8.29508 11.4539 7.38469ZM9.5 4.5C9.5 5.32843 8.82843 6 8 6C7.17157 6 6.5 5.32843 6.5 4.5C6.5 3.67157 7.17157 3 8 3C8.82843 3 9.5 3.67157 9.5 4.5ZM8 9C6.89543 9 6 9.89543 6 11C6 12.1046 6.89543 13 8 13C9.10457 13 10 12.1046 10 11C10 9.89543 9.10457 9 8 9Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


nine : Int -> Html msg
nine width =
    Svg.svg
        [ Svg.Attributes.viewBox "2 0 12 16"
        , Svg.Attributes.width (String.fromInt width)
        ]
        [ Svg.path
            [ Svg.Attributes.fillRule "evenodd"
            , Svg.Attributes.clipRule "evenodd"
            , Svg.Attributes.d "M7.85144 10.998C4.88255 10.9193 2.5 8.48789 2.5 5.5C2.5 2.46243 4.96243 0 8 0C11.0376 0 13.5 2.46243 13.5 5.5C13.5 6.55815 13.2012 7.54651 12.6833 8.38529L8.56828 15.9656L5.93172 14.5344L7.85144 10.998ZM10.0965 6.86244C9.65053 7.54725 8.87814 8 8 8C6.61929 8 5.5 6.88071 5.5 5.5C5.5 4.11929 6.61929 3 8 3C9.38071 3 10.5 4.11929 10.5 5.5C10.5 5.90629 10.3985 6.30614 10.2046 6.66322L10.0965 6.86244Z"
            , Svg.Attributes.fill "currentColor"
            ]
            []
        ]


infinity : Int -> Html msg
infinity width =
    Svg.svg
        [ Svg.Attributes.viewBox "0 0 16 16"
        , Svg.Attributes.width (String.fromInt width)
        , Svg.Attributes.fill "currentColor"
        ]
        [ Svg.g
            [ Svg.Attributes.transform "translate(6.025 -1038.1)"
            ]
            [ Svg.path
                [ Svg.Attributes.d "M-2.025 1042.1a4 4 0 0 0 0 8c2 0 4-1 5-4-1-3-3-4-5-4zm0 2s2 0 3 2c-1 2-3 2-3 2a2 2 0 1 1 0-4z"
                ]
                []
            , Svg.path
                [ Svg.Attributes.d "M5.975 1042.1a4 4 0 0 1 0 8c-2 0-4-1-5-4 1-3 3-4 5-4zm0 2s-2 0-3 2c1 2 3 2 3 2a2 2 0 1 0 0-4z"
                ]
                []
            ]
        ]


phone : Html msg
phone =
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
            , Svg.Attributes.d "M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 0 0 2.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 0 1-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 0 0-1.091-.852H4.5A2.25 2.25 0 0 0 2.25 4.5v2.25Z"
            ]
            []
        ]
