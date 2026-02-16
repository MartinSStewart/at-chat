module Evergreen.V114.Log exposing (..)

import Effect.Http
import Evergreen.V114.Discord
import Evergreen.V114.Discord.Id
import Evergreen.V114.EmailAddress
import Evergreen.V114.Emoji
import Evergreen.V114.Id
import Evergreen.V114.Postmark


type Log
    = LoginEmail (Result Evergreen.V114.Postmark.SendEmailError ()) Evergreen.V114.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    | ChangedUsers (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V114.Postmark.SendEmailError Evergreen.V114.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Emoji.Emoji Evergreen.V114.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Emoji.Emoji Evergreen.V114.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Emoji.Emoji Evergreen.V114.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Emoji.Emoji Evergreen.V114.Discord.HttpError
    | FailedToCreateDiscordPrivateChannel (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) Evergreen.V114.Discord.HttpError
