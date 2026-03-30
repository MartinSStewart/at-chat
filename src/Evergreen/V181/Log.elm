module Evergreen.V181.Log exposing (..)

import Effect.Http
import Evergreen.V181.Discord
import Evergreen.V181.EmailAddress
import Evergreen.V181.Emoji
import Evergreen.V181.Id
import Evergreen.V181.Postmark


type Log
    = LoginEmail (Result Evergreen.V181.Postmark.SendEmailError ()) Evergreen.V181.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
    | ChangedUsers (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V181.Postmark.SendEmailError Evergreen.V181.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Emoji.Emoji Evergreen.V181.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Emoji.Emoji Evergreen.V181.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Emoji.Emoji Evergreen.V181.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Emoji.Emoji Evergreen.V181.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMaybeMessage Evergreen.V181.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) Evergreen.V181.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V181.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.Discord.HttpError
