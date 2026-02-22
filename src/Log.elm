module Log exposing (Log(..), addLog, httpErrorToString, shouldNotifyAdmin, timeToString, view)

import Array exposing (Array)
import Discord
import Discord.Id
import Effect.Http as Http
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Emoji)
import Icons
import Id exposing (ChannelMessageId, Id, ThreadRouteWithMessage, UserId)
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
    | PushNotificationError (Id UserId) Http.Error
    | FailedToDeleteDiscordGuildMessage (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ThreadRouteWithMessage (Discord.Id.Id Discord.Id.MessageId) Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Discord.Id.Id Discord.Id.PrivateChannelId) (Id ChannelMessageId) (Discord.Id.Id Discord.Id.MessageId) Discord.HttpError
    | FailedToEditDiscordGuildMessage (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ThreadRouteWithMessage (Discord.Id.Id Discord.Id.MessageId) Discord.HttpError
    | FailedToEditDiscordDmMessage (Discord.Id.Id Discord.Id.PrivateChannelId) (Id ChannelMessageId) (Discord.Id.Id Discord.Id.MessageId) Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ThreadRouteWithMessage (Discord.Id.Id Discord.Id.MessageId) Emoji Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Discord.Id.Id Discord.Id.PrivateChannelId) (Id ChannelMessageId) (Discord.Id.Id Discord.Id.MessageId) Emoji Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) ThreadRouteWithMessage (Discord.Id.Id Discord.Id.MessageId) Emoji Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Discord.Id.Id Discord.Id.PrivateChannelId) (Id ChannelMessageId) (Discord.Id.Id Discord.Id.MessageId) Emoji Discord.HttpError
    | FailedToLoadDiscordUserData (Discord.Id.Id Discord.Id.UserId) Discord.HttpError


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

        PushNotificationError _ _ ->
            Just "PushNotificationError"

        FailedToDeleteDiscordGuildMessage _ _ _ _ _ ->
            Nothing

        FailedToDeleteDiscordDmMessage _ _ _ _ ->
            Nothing

        FailedToEditDiscordGuildMessage _ _ _ _ _ ->
            Nothing

        FailedToEditDiscordDmMessage _ _ _ _ ->
            Nothing

        FailedToAddReactionToDiscordGuildMessage _ _ _ _ _ _ ->
            Nothing

        FailedToAddReactionToDiscordDmMessage _ _ _ _ _ ->
            Nothing

        FailedToRemoveReactionToDiscordGuildMessage _ _ _ _ _ _ ->
            Nothing

        FailedToRemoveReactionToDiscordDmMessage _ _ _ _ _ ->
            Nothing

        FailedToLoadDiscordUserData _ _ ->
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


timeToString : Time.Zone -> Bool -> Time.Posix -> String
timeToString timezone includeYear time =
    String.padLeft 2 '0' (String.fromInt (Time.toHour timezone time))
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute timezone time))
        ++ "\u{00A0}"
        ++ String.fromInt (Time.toDay timezone time)
        ++ "/"
        ++ monthToString (Time.toMonth timezone time)
        ++ (if includeYear then
                "/" ++ String.fromInt (Time.toYear timezone time)

            else
                ""
           )


view : Time.Zone -> msg -> Bool -> Bool -> { time : Time.Posix, log : Log } -> Element msg
view timezone onPressCopyLink isCopied isHighlighted { time, log } =
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
                , timeToString timezone False time |> Ui.text
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
                    Ui.column
                        [ Ui.spacing 4 ]
                        [ tag successTag "Login Email"
                        , fieldRow "To" (MyUi.emailAddress emailAddress)
                        , fieldRow "Status" (Ui.el [ Ui.Font.color successColor ] (Ui.text "Sent"))
                        ]

                Err error ->
                    Ui.column
                        [ Ui.spacing 4 ]
                        [ tag errorTag "Login Email Failed"
                        , fieldRow "To" (MyUi.emailAddress emailAddress)
                        , errorDetails (sendEmailErrorToString error)
                        ]

        LoginsRateLimited id ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag warningTag "Rate Limited"
                , fieldRow "User" (Ui.text (Id.toString id))
                ]

        ChangedUsers id ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag infoTag "User Table Modified"
                , fieldRow "By" (Ui.text (Id.toString id))
                ]

        SendLogErrorEmailFailed error emailAddress ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Log Email Failed"
                , fieldRow "To" (MyUi.emailAddress emailAddress)
                , errorDetails (sendEmailErrorToString error)
                ]

        PushNotificationError userId error ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Push Notification Error"
                , fieldRow "User" (Ui.text (Id.toString userId))
                , fieldRow "Error" (Ui.text (httpErrorToString error))
                ]

        FailedToDeleteDiscordGuildMessage guildId channelId _ discordMessageId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord guild message delete failed"
                , fieldRow "Guild" (Ui.text (Discord.Id.toString guildId))
                , fieldRow "Channel" (Ui.text (Discord.Id.toString channelId))
                , fieldRow "Discord message id" (Ui.text (Discord.Id.toString discordMessageId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToDeleteDiscordDmMessage channelId messageId discordMessageId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord DM message delete failed"
                , fieldRow "Channel" (Ui.text (Discord.Id.toString channelId))
                , fieldRow "Message id" (Ui.text (Id.toString messageId))
                , fieldRow "Discord message id" (Ui.text (Discord.Id.toString discordMessageId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToEditDiscordGuildMessage guildId channelId _ discordMessageId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord guild message edit failed"
                , fieldRow "Guild" (Ui.text (Discord.Id.toString guildId))
                , fieldRow "Channel" (Ui.text (Discord.Id.toString channelId))
                , fieldRow "Discord message id" (Ui.text (Discord.Id.toString discordMessageId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToEditDiscordDmMessage channelId messageId discordMessageId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord DM message edit failed"
                , fieldRow "Channel" (Ui.text (Discord.Id.toString channelId))
                , fieldRow "Message id" (Ui.text (Id.toString messageId))
                , fieldRow "Discord message id" (Ui.text (Discord.Id.toString discordMessageId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToAddReactionToDiscordGuildMessage guildId channelId _ discordMessageId emoji httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Adding Discord guild reaction failed"
                , fieldRow "Guild" (Ui.text (Discord.Id.toString guildId))
                , fieldRow "Channel" (Ui.text (Discord.Id.toString channelId))
                , fieldRow "Discord message id" (Ui.text (Discord.Id.toString discordMessageId))
                , fieldRow "Emoji" (Ui.text (Emoji.toString emoji))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToAddReactionToDiscordDmMessage channelId messageId discordMessageId emoji httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Adding Discord DM reaction failed"
                , fieldRow "Channel" (Ui.text (Discord.Id.toString channelId))
                , fieldRow "Message id" (Ui.text (Id.toString messageId))
                , fieldRow "Discord message id" (Ui.text (Discord.Id.toString discordMessageId))
                , fieldRow "Emoji" (Ui.text (Emoji.toString emoji))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToRemoveReactionToDiscordGuildMessage guildId channelId _ discordMessageId emoji httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Removing Discord guild reaction failed"
                , fieldRow "Guild" (Ui.text (Discord.Id.toString guildId))
                , fieldRow "Channel" (Ui.text (Discord.Id.toString channelId))
                , fieldRow "Discord message id" (Ui.text (Discord.Id.toString discordMessageId))
                , fieldRow "Emoji" (Ui.text (Emoji.toString emoji))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToRemoveReactionToDiscordDmMessage channelId messageId discordMessageId emoji httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Removing Discord DM reaction failed"
                , fieldRow "Channel" (Ui.text (Discord.Id.toString channelId))
                , fieldRow "Message id" (Ui.text (Id.toString messageId))
                , fieldRow "Discord message id" (Ui.text (Discord.Id.toString discordMessageId))
                , fieldRow "Emoji" (Ui.text (Emoji.toString emoji))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToLoadDiscordUserData discordUserId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Loading Discord user data failed"
                , fieldRow "Discord user id" (Ui.text (Discord.Id.toString discordUserId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]


type alias TagStyle =
    { background : Ui.Color
    , font : Ui.Color
    , border : Ui.Color
    }


successTag : TagStyle
successTag =
    { background = Ui.rgb 220 252 231
    , font = Ui.rgb 22 101 52
    , border = Ui.rgb 187 247 208
    }


errorTag : TagStyle
errorTag =
    { background = Ui.rgb 254 226 226
    , font = Ui.rgb 153 27 27
    , border = Ui.rgb 254 202 202
    }


warningTag : TagStyle
warningTag =
    { background = Ui.rgb 254 249 195
    , font = Ui.rgb 133 77 14
    , border = Ui.rgb 253 224 71
    }


infoTag : TagStyle
infoTag =
    { background = Ui.rgb 224 231 255
    , font = Ui.rgb 55 48 163
    , border = Ui.rgb 199 210 254
    }


tag : TagStyle -> String -> Element msg
tag style label =
    Ui.el
        [ Ui.background style.background
        , Ui.Font.color style.font
        , Ui.borderColor style.border
        , Ui.border 1
        , Ui.rounded 4
        , Ui.paddingXY 6 2
        , Ui.Font.size 12
        , Ui.Font.bold
        , Ui.width Ui.shrink
        ]
        (Ui.text label)


fieldRow : String -> Element msg -> Element msg
fieldRow label value =
    Ui.row
        [ Ui.spacing 6 ]
        [ Ui.el
            [ Ui.Font.color MyUi.gray
            , Ui.Font.size 13
            , Ui.width Ui.shrink
            , MyUi.noShrinking
            , Ui.alignTop
            ]
            (Ui.text (label ++ ":"))
        , Ui.el [ Ui.Font.size 13 ] value
        ]


successColor : Ui.Color
successColor =
    Ui.rgb 22 101 52


errorDetails : List (Element msg) -> Element msg
errorDetails content =
    Ui.row
        [ Ui.spacing 6 ]
        [ Ui.el
            [ Ui.Font.color MyUi.gray
            , Ui.Font.size 13
            , Ui.width Ui.shrink
            , MyUi.noShrinking
            , Ui.alignTop
            ]
            (Ui.text "Error:")
        , Ui.Prose.paragraph [ Ui.Font.size 13, Ui.paddingXY 0 5 ] content
        ]


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadBody body ->
            body

        Http.BadUrl string ->
            "bad url " ++ string

        Http.Timeout ->
            "timeout"

        Http.NetworkError ->
            "network error"

        Http.BadStatus int ->
            "bad status " ++ String.fromInt int


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
