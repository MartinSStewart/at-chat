module Evergreen.V115.Log exposing (..)

import Effect.Http
import Evergreen.V115.Discord
import Evergreen.V115.Discord.Id
import Evergreen.V115.EmailAddress
import Evergreen.V115.Emoji
import Evergreen.V115.Id
import Evergreen.V115.Postmark


type Log
    = LoginEmail (Result Evergreen.V115.Postmark.SendEmailError ()) Evergreen.V115.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    | ChangedUsers (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V115.Postmark.SendEmailError Evergreen.V115.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Emoji.Emoji Evergreen.V115.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Emoji.Emoji Evergreen.V115.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Emoji.Emoji Evergreen.V115.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Emoji.Emoji Evergreen.V115.Discord.HttpError
    | FailedToCreateDiscordPrivateChannel (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Evergreen.V115.Discord.HttpError
