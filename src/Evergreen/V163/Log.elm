module Evergreen.V163.Log exposing (..)

import Effect.Http
import Evergreen.V163.Discord
import Evergreen.V163.EmailAddress
import Evergreen.V163.Emoji
import Evergreen.V163.Id
import Evergreen.V163.Postmark


type Log
    = LoginEmail (Result Evergreen.V163.Postmark.SendEmailError ()) Evergreen.V163.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
    | ChangedUsers (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V163.Postmark.SendEmailError Evergreen.V163.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) Evergreen.V163.Id.ThreadRouteWithMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) Evergreen.V163.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) Evergreen.V163.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) Evergreen.V163.Id.ThreadRouteWithMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) Evergreen.V163.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) Evergreen.V163.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) Evergreen.V163.Id.ThreadRouteWithMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) Evergreen.V163.Emoji.Emoji Evergreen.V163.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) Evergreen.V163.Emoji.Emoji Evergreen.V163.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) Evergreen.V163.Id.ThreadRouteWithMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) Evergreen.V163.Emoji.Emoji Evergreen.V163.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) Evergreen.V163.Emoji.Emoji Evergreen.V163.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) Evergreen.V163.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) Evergreen.V163.Id.ThreadRouteWithMaybeMessage Evergreen.V163.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) Evergreen.V163.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V163.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) Evergreen.V163.Discord.HttpError
