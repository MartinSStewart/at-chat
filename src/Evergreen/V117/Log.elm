module Evergreen.V117.Log exposing (..)

import Effect.Http
import Evergreen.V117.Discord
import Evergreen.V117.Discord.Id
import Evergreen.V117.EmailAddress
import Evergreen.V117.Emoji
import Evergreen.V117.Id
import Evergreen.V117.Postmark


type Log
    = LoginEmail (Result Evergreen.V117.Postmark.SendEmailError ()) Evergreen.V117.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
    | ChangedUsers (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V117.Postmark.SendEmailError Evergreen.V117.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Emoji.Emoji Evergreen.V117.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Emoji.Emoji Evergreen.V117.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Emoji.Emoji Evergreen.V117.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Emoji.Emoji Evergreen.V117.Discord.HttpError
    | FailedToCreateDiscordPrivateChannel (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Evergreen.V117.Discord.HttpError
