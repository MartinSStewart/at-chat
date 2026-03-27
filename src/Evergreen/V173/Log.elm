module Evergreen.V173.Log exposing (..)

import Effect.Http
import Evergreen.V173.Discord
import Evergreen.V173.EmailAddress
import Evergreen.V173.Emoji
import Evergreen.V173.Id
import Evergreen.V173.Postmark


type Log
    = LoginEmail (Result Evergreen.V173.Postmark.SendEmailError ()) Evergreen.V173.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
    | ChangedUsers (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V173.Postmark.SendEmailError Evergreen.V173.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Emoji.Emoji Evergreen.V173.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Emoji.Emoji Evergreen.V173.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Emoji.Emoji Evergreen.V173.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Emoji.Emoji Evergreen.V173.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMaybeMessage Evergreen.V173.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) Evergreen.V173.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V173.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.Discord.HttpError
