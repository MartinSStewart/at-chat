module UiViewer exposing (main)

{-| This module is for letting you view parts of the app UI that would be difficult to reach under normal usage.
Start `lamdera live` and go to localhost:8000/src/UiViewer.elm to use it.
-}

import Backend
import Discord
import Discord.Id
import Effect.Http as Http
import Email.Html
import EmailAddress
import Html exposing (Html)
import Html.Attributes
import Id
import Log
import MyUi
import Postmark
import String.Nonempty exposing (NonemptyString)
import Time
import Ui
import Ui.Font


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


logExamples : Ui.Element ()
logExamples =
    let
        exampleEmail =
            EmailAddress.fromString "user@example.com"

        exampleTime =
            Time.millisToPosix 1700000000000

        noOp =
            ()

        exampleDiscordId str =
            Discord.Id.fromString str

        logEntry log =
            Log.view Time.utc noOp False False { time = exampleTime, log = log }
    in
    Ui.column
        [ Ui.spacing 24 ]
        (List.filterMap identity
            [ -- LoginEmail success
              exampleEmail
                |> Maybe.map
                    (\email ->
                        logEntry (Log.LoginEmail (Ok ()) email)
                    )

            -- LoginEmail failure (network error)
            , exampleEmail
                |> Maybe.map
                    (\email ->
                        logEntry (Log.LoginEmail (Err Postmark.NetworkError) email)
                    )

            -- LoginEmail failure (unknown error)
            , exampleEmail
                |> Maybe.map
                    (\email ->
                        logEntry (Log.LoginEmail (Err (Postmark.UnknownError { statusCode = 500, body = "Internal Server Error" })) email)
                    )

            -- LoginsRateLimited
            , Just (logEntry (Log.LoginsRateLimited (Id.fromInt 42)))

            -- ChangedUsers
            , Just (logEntry (Log.ChangedUsers (Id.fromInt 7)))

            -- SendLogErrorEmailFailed
            , exampleEmail
                |> Maybe.map
                    (\email ->
                        logEntry (Log.SendLogErrorEmailFailed Postmark.Timeout email)
                    )

            -- PushNotificationError
            , Just (logEntry (Log.PushNotificationError (Id.fromInt 15) Http.NetworkError))

            -- PushNotificationError with BadStatus
            , Just (logEntry (Log.PushNotificationError (Id.fromInt 15) (Http.BadStatus 403)))

            -- FailedToDeleteDiscordMessage
            , Maybe.map3
                (\guildId channelId messageId ->
                    logEntry
                        (Log.FailedToDeleteDiscordMessage
                            guildId
                            channelId
                            (Id.NoThreadWithMessage (Id.fromInt 0))
                            messageId
                            (Discord.NotFound404 Discord.UnknownMessage10008)
                        )
                )
                (exampleDiscordId "111222333444555666")
                (exampleDiscordId "777888999000111222")
                (exampleDiscordId "333444555666777888")
            ]
        )
