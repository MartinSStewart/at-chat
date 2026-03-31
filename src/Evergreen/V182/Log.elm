module Evergreen.V182.Log exposing (..)

import Effect.Http
import Evergreen.V182.Discord
import Evergreen.V182.EmailAddress
import Evergreen.V182.Emoji
import Evergreen.V182.Id
import Evergreen.V182.Postmark


type Log
    = LoginEmail (Result Evergreen.V182.Postmark.SendEmailError ()) Evergreen.V182.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
    | ChangedUsers (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V182.Postmark.SendEmailError Evergreen.V182.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) Evergreen.V182.Id.ThreadRouteWithMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) Evergreen.V182.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) Evergreen.V182.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) Evergreen.V182.Id.ThreadRouteWithMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) Evergreen.V182.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) Evergreen.V182.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) Evergreen.V182.Id.ThreadRouteWithMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) Evergreen.V182.Emoji.Emoji Evergreen.V182.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) Evergreen.V182.Emoji.Emoji Evergreen.V182.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) Evergreen.V182.Id.ThreadRouteWithMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) Evergreen.V182.Emoji.Emoji Evergreen.V182.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) Evergreen.V182.Emoji.Emoji Evergreen.V182.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) Evergreen.V182.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) Evergreen.V182.Id.ThreadRouteWithMaybeMessage Evergreen.V182.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) Evergreen.V182.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V182.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) Evergreen.V182.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) Evergreen.V182.Discord.HttpError
    | EmptyDiscordMessage String
