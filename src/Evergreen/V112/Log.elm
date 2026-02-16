module Evergreen.V112.Log exposing (..)

import Effect.Http
import Evergreen.V112.Discord
import Evergreen.V112.Discord.Id
import Evergreen.V112.EmailAddress
import Evergreen.V112.Emoji
import Evergreen.V112.Id
import Evergreen.V112.Postmark


type Log
    = LoginEmail (Result Evergreen.V112.Postmark.SendEmailError ()) Evergreen.V112.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
    | ChangedUsers (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V112.Postmark.SendEmailError Evergreen.V112.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Emoji.Emoji Evergreen.V112.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Emoji.Emoji Evergreen.V112.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Emoji.Emoji Evergreen.V112.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Emoji.Emoji Evergreen.V112.Discord.HttpError
    | FailedToCreateDiscordPrivateChannel (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) Evergreen.V112.Discord.HttpError
