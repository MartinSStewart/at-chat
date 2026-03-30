module Evergreen.V179.Log exposing (..)

import Effect.Http
import Evergreen.V179.Discord
import Evergreen.V179.EmailAddress
import Evergreen.V179.Emoji
import Evergreen.V179.Id
import Evergreen.V179.Postmark


type Log
    = LoginEmail (Result Evergreen.V179.Postmark.SendEmailError ()) Evergreen.V179.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
    | ChangedUsers (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V179.Postmark.SendEmailError Evergreen.V179.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Emoji.Emoji Evergreen.V179.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Emoji.Emoji Evergreen.V179.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Emoji.Emoji Evergreen.V179.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Emoji.Emoji Evergreen.V179.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMaybeMessage Evergreen.V179.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) Evergreen.V179.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V179.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.Discord.HttpError
