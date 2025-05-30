module Log exposing (Log(..), addLog, shouldNotifyAdmin, view)

import Array exposing (Array)
import EmailAddress exposing (EmailAddress)
import Icons
import Id exposing (Id, UserId)
import MyUi
import Postmark
import Time exposing (Month(..))
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Prose


type Log
    = LoginEmail (Result Postmark.SendEmailError ()) EmailAddress
    | LoginsRateLimited (Id UserId)
    | ChangedUsers (Id UserId)
    | SendLogErrorEmailFailed Postmark.SendEmailError EmailAddress


shouldNotifyAdmin : Log -> Maybe String
shouldNotifyAdmin log =
    case log of
        LoginEmail _ _ ->
            Nothing

        LoginsRateLimited _ ->
            Just "LoginsRateLimited"

        ChangedUsers _ ->
            Nothing

        SendLogErrorEmailFailed _ _ ->
            Nothing


addLog :
    Time.Posix
    -> Log
    -> { a | logs : Array { time : Time.Posix, log : Log } }
    -> { a | logs : Array { time : Time.Posix, log : Log } }
addLog time log model =
    { model | logs = Array.push { time = time, log = log } model.logs }


monthToString : Month -> String
monthToString month =
    case month of
        Jan ->
            "1"

        Feb ->
            "2"

        Mar ->
            "3"

        Apr ->
            "4"

        May ->
            "5"

        Jun ->
            "6"

        Jul ->
            "7"

        Aug ->
            "8"

        Sep ->
            "9"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


timeToString : Bool -> Time.Posix -> String
timeToString includeYear time =
    String.padLeft 2 '0' (String.fromInt (Time.toHour Time.utc time))
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute Time.utc time))
        ++ "\u{00A0}"
        ++ String.fromInt (Time.toDay Time.utc time)
        ++ "/"
        ++ monthToString (Time.toMonth Time.utc time)
        ++ (if includeYear then
                "/" ++ String.fromInt (Time.toYear Time.utc time)

            else
                ""
           )


view : msg -> Bool -> Bool -> { time : Time.Posix, log : Log } -> Element msg
view onPressCopyLink isCopied isHighlighted { time, log } =
    Ui.row
        [ Ui.spacingWith { horizontal = 16, vertical = 2 }
        , Ui.attrIf isHighlighted (Ui.background (Ui.rgb 255 246 207))
        , Ui.paddingXY 0 4
        , Ui.wrap
        ]
        [ Ui.column
            [ Ui.spacing 4
            , Ui.width Ui.shrink
            , Ui.alignTop
            , Ui.Font.size 14
            ]
            [ Ui.row
                [ Ui.Font.color MyUi.gray
                , Ui.width Ui.shrink
                , Ui.spacing 4
                , Ui.Input.button onPressCopyLink
                , Ui.id "Log_copyLink"
                ]
                [ Ui.el [ Ui.move (Ui.up 1) ] Icons.link
                , timeToString False time |> Ui.text
                ]
            , if isCopied then
                Ui.text "Link copied!"

              else
                Ui.none
            ]
        , logContent log |> Ui.el [ Ui.widthMin 350 ]
        ]


logContent : Log -> Element msg
logContent log =
    case log of
        LoginEmail result emailAddress ->
            case result of
                Ok () ->
                    Ui.Prose.paragraph
                        []
                        [ Ui.text "Login email sent to "
                        , MyUi.emailAddress emailAddress
                        , Ui.text " successfully"
                        ]

                Err error ->
                    Ui.Prose.paragraph
                        []
                        ([ Ui.text "Failed to send login email to "
                         , MyUi.emailAddress emailAddress
                         , Ui.text ". "
                         ]
                            ++ sendEmailErrorToString error
                        )

        LoginsRateLimited id ->
            "User " ++ Id.toString id ++ " has their login rate limited" |> Ui.text

        ChangedUsers id ->
            "User " ++ Id.toString id ++ " modified the user table" |> Ui.text

        SendLogErrorEmailFailed error emailAddress ->
            Ui.column
                [ Ui.spacing 2 ]
                (Ui.text
                    ("Failed to send email to "
                        ++ EmailAddress.toString emailAddress
                        ++ " about an important error that was logged. Http error: "
                    )
                    :: sendEmailErrorToString error
                )


sendEmailErrorToString : Postmark.SendEmailError -> List (Element msg)
sendEmailErrorToString sendEmailError =
    case sendEmailError of
        Postmark.UnknownError { statusCode, body } ->
            [ String.fromInt statusCode ++ " " ++ body |> Ui.text ]

        Postmark.PostmarkError response ->
            ("PostmarkError "
                ++ String.fromInt response.errorCode
                ++ " "
                ++ response.message
                ++ " "
                |> Ui.text
            )
                :: List.intersperse (Ui.text ", ") (List.map MyUi.emailAddress response.to)

        Postmark.NetworkError ->
            [ Ui.text "NetworkError" ]

        Postmark.Timeout ->
            [ Ui.text "Timeout" ]

        Postmark.BadUrl string ->
            [ Ui.text ("BadUrl " ++ string) ]
