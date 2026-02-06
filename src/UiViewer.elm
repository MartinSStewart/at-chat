module UiViewer exposing (main)

{-| This module is for letting you view parts of the app UI that would be difficult to reach under normal usage.
Start `lamdera live` and go to localhost:8000/src/UiViewer.elm to use it.
-}

import Backend
import Email.Html
import Html exposing (Html)
import Html.Attributes
import String.Nonempty exposing (NonemptyString)
import Ui


main : Html msg
main =
    Ui.layout
        []
        (Ui.column
            [ Ui.spacing 16 ]
            [ Ui.html loginEmail
            ]
        )


emailView : NonemptyString -> Email.Html.Html -> Html msg
emailView subject content =
    Html.div
        [ Html.Attributes.style "background-color" "white" ]
        [ Html.span []
            [ String.Nonempty.toString subject ++ " " |> Html.text
            , Html.input
                [ Html.Attributes.readonly True
                , Html.Attributes.type_ "text"
                , Html.Attributes.value (Email.Html.toString content)
                ]
                []
            ]
        , Email.Html.toHtml content
        ]


loginEmail : Html msg
loginEmail =
    emailView
        Backend.loginEmailSubject
        (Backend.loginEmailContent 12345678)
