module Evergreen.V171.Log exposing (..)

import Effect.Http
import Evergreen.V171.Discord
import Evergreen.V171.EmailAddress
import Evergreen.V171.Emoji
import Evergreen.V171.Id
import Evergreen.V171.Postmark


type Log
    = LoginEmail (Result Evergreen.V171.Postmark.SendEmailError ()) Evergreen.V171.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
    | ChangedUsers (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V171.Postmark.SendEmailError Evergreen.V171.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) Evergreen.V171.Id.ThreadRouteWithMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) Evergreen.V171.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) Evergreen.V171.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) Evergreen.V171.Id.ThreadRouteWithMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) Evergreen.V171.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) Evergreen.V171.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) Evergreen.V171.Id.ThreadRouteWithMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) Evergreen.V171.Emoji.Emoji Evergreen.V171.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) Evergreen.V171.Emoji.Emoji Evergreen.V171.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) Evergreen.V171.Id.ThreadRouteWithMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) Evergreen.V171.Emoji.Emoji Evergreen.V171.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) Evergreen.V171.Emoji.Emoji Evergreen.V171.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) Evergreen.V171.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) Evergreen.V171.Id.ThreadRouteWithMaybeMessage Evergreen.V171.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) Evergreen.V171.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V171.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) Evergreen.V171.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) Evergreen.V171.Discord.HttpError
