module Evergreen.V161.Log exposing (..)

import Effect.Http
import Evergreen.V161.Discord
import Evergreen.V161.EmailAddress
import Evergreen.V161.Emoji
import Evergreen.V161.Id
import Evergreen.V161.Postmark


type Log
    = LoginEmail (Result Evergreen.V161.Postmark.SendEmailError ()) Evergreen.V161.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
    | ChangedUsers (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V161.Postmark.SendEmailError Evergreen.V161.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Emoji.Emoji Evergreen.V161.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Emoji.Emoji Evergreen.V161.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Emoji.Emoji Evergreen.V161.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) Evergreen.V161.Emoji.Emoji Evergreen.V161.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) Evergreen.V161.Id.ThreadRouteWithMaybeMessage Evergreen.V161.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) Evergreen.V161.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V161.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) Evergreen.V161.Discord.HttpError
