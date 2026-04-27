module Evergreen.V209.Log exposing (..)

import Effect.Http
import Evergreen.V209.Discord
import Evergreen.V209.EmailAddress
import Evergreen.V209.Emoji
import Evergreen.V209.Id
import Evergreen.V209.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V209.Postmark.SendEmailError ()) Evergreen.V209.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
    | ChangedUsers (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V209.Postmark.SendEmailError Evergreen.V209.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Emoji.Emoji Evergreen.V209.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Emoji.Emoji Evergreen.V209.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Emoji.Emoji Evergreen.V209.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Emoji.Emoji Evergreen.V209.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMaybeMessage Evergreen.V209.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) Evergreen.V209.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V209.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V209.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
