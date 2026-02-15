module UiViewer exposing (main)

{-| This module is for letting you view parts of the app UI that would be difficult to reach under normal usage.
Start `lamdera live` and go to localhost:8000/src/UiViewer.elm to use it.
-}

import Backend
import Discord
import Discord.Id
import Effect.Http as Http
import Email.Html
import EmailAddress exposing (EmailAddress)
import Html exposing (Html)
import Html.Attributes
import Id
import Log exposing (Log)
import Postmark
import String.Nonempty exposing (NonemptyString)
import Time
import Ui
import Ui.Font
import Unsafe


main : Html ()
main =
    Ui.layout
        []
        (Ui.column
            [ Ui.spacing 16, Ui.padding 16 ]
            [ Ui.column
                [ Ui.background (Ui.rgb 255 255 255) ]
                [ Ui.el [ Ui.Font.size 24, Ui.Font.bold ] (Ui.text "Emails")
                , Ui.html loginEmail
                ]
            , Ui.column
                [ Ui.background (Ui.rgb 255 255 255), Ui.Font.family [ Ui.Font.sansSerif ] ]
                [ Ui.el [ Ui.Font.size 24, Ui.Font.bold ] (Ui.text "Log entries")
                , logExamples
                ]
            ]
        )


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


exampleEmail : EmailAddress
exampleEmail =
    Unsafe.emailAddress "user@example.com"


logExamples : Ui.Element ()
logExamples =
    let
        exampleTime =
            Time.millisToPosix 1700000000000

        logEntry : Log -> Ui.Element ()
        logEntry log =
            Log.view Time.utc () False False { time = exampleTime, log = log }
    in
    Ui.column
        [ Ui.spacing 24 ]
        [ logEntry (Log.LoginEmail (Ok ()) exampleEmail)
        , logEntry
            (Log.LoginEmail
                (Postmark.PostmarkError
                    { errorCode = 400
                    , message = "The 'From' address you supplied (no-reply@at-chat.app) is not a Sender Signature on your account. Please add and confirm this address in order to be able to use it in the 'From' field of your messages. "
                    , to = [ exampleEmail ]
                    }
                    |> Err
                )
                exampleEmail
            )
        , logEntry (Log.LoginEmail (Err (Postmark.UnknownError { statusCode = 500, body = "Internal Server Error" })) exampleEmail)
        , logEntry (Log.LoginsRateLimited (Id.fromInt 42))
        , logEntry (Log.ChangedUsers (Id.fromInt 7))
        , logEntry (Log.SendLogErrorEmailFailed Postmark.Timeout exampleEmail)
        , logEntry (Log.PushNotificationError (Id.fromInt 15) Http.NetworkError)
        , logEntry (Log.PushNotificationError (Id.fromInt 15) (Http.BadStatus 403))
        , logEntry
            (Log.FailedToDeleteDiscordGuildMessage
                (Unsafe.uint64 "111222333444555666" |> Discord.Id.fromUInt64)
                (Unsafe.uint64 "777888999000111222" |> Discord.Id.fromUInt64)
                (Id.NoThreadWithMessage (Id.fromInt 0))
                (Unsafe.uint64 "333444555666777888" |> Discord.Id.fromUInt64)
                (Discord.NotFound404 Discord.UnknownMessage10008)
            )
        ]
