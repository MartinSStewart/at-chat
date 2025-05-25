module EmailViewer exposing (main)

import Backend
import Email.Html
import Html exposing (Html)
import Html.Attributes
import String.Nonempty exposing (NonemptyString)


main : Html msg
main =
    [ loginEmail ]
        |> Html.div []


emailView : NonemptyString -> Email.Html.Html -> Html msg
emailView subject content =
    Html.div
        []
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
