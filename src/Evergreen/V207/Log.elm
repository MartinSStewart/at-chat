module Evergreen.V207.Log exposing (..)

import Effect.Http
import Evergreen.V207.Discord
import Evergreen.V207.EmailAddress
import Evergreen.V207.Emoji
import Evergreen.V207.Id
import Evergreen.V207.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V207.Postmark.SendEmailError ()) Evergreen.V207.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
    | ChangedUsers (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V207.Postmark.SendEmailError Evergreen.V207.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Emoji.Emoji Evergreen.V207.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Emoji.Emoji Evergreen.V207.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Emoji.Emoji Evergreen.V207.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Emoji.Emoji Evergreen.V207.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMaybeMessage Evergreen.V207.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) Evergreen.V207.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V207.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V207.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
