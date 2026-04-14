module Evergreen.V199.Log exposing (..)

import Effect.Http
import Evergreen.V199.Discord
import Evergreen.V199.EmailAddress
import Evergreen.V199.Emoji
import Evergreen.V199.Id
import Evergreen.V199.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V199.Postmark.SendEmailError ()) Evergreen.V199.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
    | ChangedUsers (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V199.Postmark.SendEmailError Evergreen.V199.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Emoji.Emoji Evergreen.V199.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Emoji.Emoji Evergreen.V199.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Emoji.Emoji Evergreen.V199.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Emoji.Emoji Evergreen.V199.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMaybeMessage Evergreen.V199.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) Evergreen.V199.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V199.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V199.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
