module Log exposing (Log(..), MsgConfig, httpErrorToString, shouldNotifyAdmin, timeToString, view)

import Discord
import Effect.Browser.Dom as Dom
import Effect.Http as Http
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Emoji)
import Icons
import Id exposing (ChannelMessageId, Id, StickerId, ThreadRouteWithMaybeMessage, ThreadRouteWithMessage, UserId)
import List.Nonempty exposing (Nonempty)
import MyUi
import Postmark
import Time exposing (Month(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Input
import Ui.Prose


type Log
    = LoginEmail (Result Postmark.SendEmailError ()) EmailAddress
    | LoginsRateLimited (Id UserId)
    | ChangedUsers (Id UserId)
    | SendLogErrorEmailFailed Postmark.SendEmailError EmailAddress
    | PushNotificationError (Id UserId) Http.Error
    | FailedToDeleteDiscordGuildMessage (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) ThreadRouteWithMessage (Discord.Id Discord.MessageId) Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Discord.Id Discord.PrivateChannelId) (Id ChannelMessageId) (Discord.Id Discord.MessageId) Discord.HttpError
    | FailedToEditDiscordGuildMessage (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) ThreadRouteWithMessage (Discord.Id Discord.MessageId) Discord.HttpError
    | FailedToEditDiscordDmMessage (Discord.Id Discord.PrivateChannelId) (Id ChannelMessageId) (Discord.Id Discord.MessageId) Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) ThreadRouteWithMessage (Discord.Id Discord.MessageId) Emoji Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Discord.Id Discord.PrivateChannelId) (Id ChannelMessageId) (Discord.Id Discord.MessageId) Emoji Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) ThreadRouteWithMessage (Discord.Id Discord.MessageId) Emoji Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Discord.Id Discord.PrivateChannelId) (Id ChannelMessageId) (Discord.Id Discord.MessageId) Emoji Discord.HttpError
    | FailedToLoadDiscordUserData (Discord.Id Discord.UserId) Discord.HttpError
    | FailedToSendDiscordGuildMessage (Discord.Id Discord.UserId) (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) ThreadRouteWithMaybeMessage Discord.HttpError
    | FailedToSendDiscordDmMessage (Discord.Id Discord.UserId) (Discord.Id Discord.PrivateChannelId) Discord.HttpError
    | FailedToGetDiscordUserAvatars Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Discord.Id Discord.UserId) (Discord.Id Discord.GuildId) Discord.HttpError
    | JoinedDiscordThreadFailed (Discord.Id Discord.GuildId) Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (Nonempty ( Id StickerId, Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Discord.HttpError
    | FailedToGenerateScheduledBackup Http.Error


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

        FailedToSendDiscordGuildMessage _ _ _ _ _ ->
            Nothing

        FailedToSendDiscordDmMessage _ _ _ ->
            Nothing

        FailedToGetDiscordUserAvatars _ ->
            Nothing

        FailedToParseDiscordWebsocket _ _ ->
            Nothing

        FailedToGetDataForJoinedOrCreatedDiscordGuild _ _ _ ->
            Nothing

        JoinedDiscordThreadFailed _ _ ->
            Nothing

        EmptyDiscordMessage _ ->
            Nothing

        FailedToLoadDiscordGuildStickers _ _ ->
            Nothing

        FailedToLoadDiscordStandardStickerPacks _ ->
            Nothing

        FailedToGenerateScheduledBackup _ ->
            Nothing


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


type alias MsgConfig msg =
    { onPressCopyLink : msg
    , onPressCopy : String -> msg
    , onPressHide : msg
    , onPressUnhide : msg
    }


view : Bool -> Bool -> Time.Zone -> MsgConfig msg -> Bool -> Bool -> { time : Time.Posix, log : Log } -> Element msg
view isMobile2 isHidden timezone msgConfig isCopied isHighlighted { time, log } =
    Ui.el
        [ Ui.attrIf isHighlighted (Ui.background MyUi.mentionColor)
        , Ui.paddingXY 8 4
        , Ui.widthMin 350
        , Ui.attrIf isHidden (Ui.opacity 0.5)
        , Ui.row
            [ Ui.Font.color MyUi.font3
            , Ui.width Ui.shrink
            , Ui.spacing 4
            , Ui.contentCenterY
            , Ui.Font.size 14
            , Ui.alignRight
            , Ui.paddingXY 8 4
            ]
            [ if isCopied then
                Ui.text "Link copied!"

              else
                Ui.none
            , Ui.el
                [ Ui.move (Ui.up 1)
                , Ui.Input.button msgConfig.onPressCopyLink
                , Ui.id "Log_copyLink"
                , MyUi.hover isMobile2 [ Ui.Anim.fontColor MyUi.font1 ]
                ]
                Icons.link
            , timeToString timezone False time |> Ui.text
            , Ui.el
                [ Ui.Input.button
                    (if isHidden then
                        msgConfig.onPressUnhide

                     else
                        msgConfig.onPressHide
                    )
                , Ui.alignTop
                , Ui.Font.size 12
                , Ui.Font.color MyUi.font3
                , Ui.width Ui.shrink
                , MyUi.hover isMobile2 [ Ui.Anim.fontColor MyUi.font1 ]
                ]
                (Ui.html
                    (if isHidden then
                        Icons.closedEye

                     else
                        Icons.openEye
                    )
                )
            ]
            |> Ui.inFront
        ]
        (logContent msgConfig.onPressCopy log)


logContent : (String -> msg) -> Log -> Element msg
logContent onPressCopy log =
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
                , fieldRow "Guild" (Ui.text (Discord.idToString guildId))
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Discord message id" (Ui.text (Discord.idToString discordMessageId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToDeleteDiscordDmMessage channelId messageId discordMessageId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord DM message delete failed"
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Message id" (Ui.text (Id.toString messageId))
                , fieldRow "Discord message id" (Ui.text (Discord.idToString discordMessageId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToEditDiscordGuildMessage guildId channelId _ discordMessageId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord guild message edit failed"
                , fieldRow "Guild" (Ui.text (Discord.idToString guildId))
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Discord message id" (Ui.text (Discord.idToString discordMessageId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToEditDiscordDmMessage channelId messageId discordMessageId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord DM message edit failed"
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Message id" (Ui.text (Id.toString messageId))
                , fieldRow "Discord message id" (Ui.text (Discord.idToString discordMessageId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToAddReactionToDiscordGuildMessage guildId channelId _ discordMessageId emoji httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Adding Discord guild reaction failed"
                , fieldRow "Guild" (Ui.text (Discord.idToString guildId))
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Discord message id" (Ui.text (Discord.idToString discordMessageId))
                , fieldRow "Emoji" (Ui.text (Emoji.toString emoji))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToAddReactionToDiscordDmMessage channelId messageId discordMessageId emoji httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Adding Discord DM reaction failed"
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Message id" (Ui.text (Id.toString messageId))
                , fieldRow "Discord message id" (Ui.text (Discord.idToString discordMessageId))
                , fieldRow "Emoji" (Ui.text (Emoji.toString emoji))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToRemoveReactionToDiscordGuildMessage guildId channelId _ discordMessageId emoji httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Removing Discord guild reaction failed"
                , fieldRow "Guild" (Ui.text (Discord.idToString guildId))
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Discord message id" (Ui.text (Discord.idToString discordMessageId))
                , fieldRow "Emoji" (Ui.text (Emoji.toString emoji))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToRemoveReactionToDiscordDmMessage channelId messageId discordMessageId emoji httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Removing Discord DM reaction failed"
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Message id" (Ui.text (Id.toString messageId))
                , fieldRow "Discord message id" (Ui.text (Discord.idToString discordMessageId))
                , fieldRow "Emoji" (Ui.text (Emoji.toString emoji))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToLoadDiscordUserData discordUserId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Loading Discord user data failed"
                , fieldRow "Discord user id" (Ui.text (Discord.idToString discordUserId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToSendDiscordGuildMessage discordUserId guildId channelId _ httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Sending Discord guild message failed"
                , fieldRow "User" (Ui.text (Discord.idToString discordUserId))
                , fieldRow "Guild" (Ui.text (Discord.idToString guildId))
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToSendDiscordDmMessage discordUserId channelId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Sending Discord DM message failed"
                , fieldRow "User" (Ui.text (Discord.idToString discordUserId))
                , fieldRow "Channel" (Ui.text (Discord.idToString channelId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToGetDiscordUserAvatars httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Loading Discord user avatars failed"
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToParseDiscordWebsocket maybeName jsonError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag
                    errorTag
                    (case maybeName of
                        Just name ->
                            "Parsing Discord websocket failed (" ++ name ++ ")"

                        Nothing ->
                            "Parsing Discord websocket failed"
                    )
                , MyUi.errorBox (Dom.id "admin_FailedToParseDiscordWebsocket") onPressCopy jsonError
                ]

        FailedToGetDataForJoinedOrCreatedDiscordGuild discordUserId guildId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord data for guild that was created or joined failed"
                , fieldRow "User" (Ui.text (Discord.idToString discordUserId))
                , fieldRow "Guild" (Ui.text (Discord.idToString guildId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        JoinedDiscordThreadFailed guildId httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Joining Discord thread failed"
                , fieldRow "Guild" (Ui.text (Discord.idToString guildId))
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        EmptyDiscordMessage message ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord message has no content"
                , MyUi.errorBox (Dom.id "admin_DiscordMessageNoContent") onPressCopy message
                ]

        FailedToLoadDiscordGuildStickers nonempty totalStickers ->
            Ui.column
                [ Ui.spacing 4 ]
                (tag errorTag "Discord guild stickers failed to load"
                    :: fieldRow "Total stickers" (Ui.text (String.fromInt totalStickers))
                    :: List.map
                        (\( stickerId, error ) ->
                            fieldRow ("Sticker " ++ Id.toString stickerId) (Ui.text (httpErrorToString error))
                        )
                        (List.Nonempty.toList nonempty)
                )

        FailedToLoadDiscordStandardStickerPacks httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Discord standard sticker packs failed to load"
                , fieldRow "Error" (Ui.text (Discord.httpErrorToString httpError))
                ]

        FailedToGenerateScheduledBackup httpError ->
            Ui.column
                [ Ui.spacing 4 ]
                [ tag errorTag "Scheduled backend backup generation failed"
                , fieldRow "Error" (Ui.text (httpErrorToString httpError))
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
            [ Ui.Font.color MyUi.font3
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
            [ Ui.Font.color MyUi.font3
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
