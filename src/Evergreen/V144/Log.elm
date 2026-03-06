module Evergreen.V144.Log exposing (..)

import Effect.Http
import Evergreen.V144.Discord
import Evergreen.V144.EmailAddress
import Evergreen.V144.Emoji
import Evergreen.V144.Id
import Evergreen.V144.Postmark


type Log
    = LoginEmail (Result Evergreen.V144.Postmark.SendEmailError ()) Evergreen.V144.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
    | ChangedUsers (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V144.Postmark.SendEmailError Evergreen.V144.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Emoji.Emoji Evergreen.V144.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Emoji.Emoji Evergreen.V144.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Emoji.Emoji Evergreen.V144.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) Evergreen.V144.Emoji.Emoji Evergreen.V144.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) Evergreen.V144.Id.ThreadRouteWithMaybeMessage Evergreen.V144.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) Evergreen.V144.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V144.Discord.HttpError
    | FailedToParseDiscordWebsocket String
