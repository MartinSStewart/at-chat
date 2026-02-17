module Evergreen.V116.Log exposing (..)

import Effect.Http
import Evergreen.V116.Discord
import Evergreen.V116.Discord.Id
import Evergreen.V116.EmailAddress
import Evergreen.V116.Emoji
import Evergreen.V116.Id
import Evergreen.V116.Postmark


type Log
    = LoginEmail (Result Evergreen.V116.Postmark.SendEmailError ()) Evergreen.V116.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    | ChangedUsers (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V116.Postmark.SendEmailError Evergreen.V116.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Emoji.Emoji Evergreen.V116.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Emoji.Emoji Evergreen.V116.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Emoji.Emoji Evergreen.V116.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Emoji.Emoji Evergreen.V116.Discord.HttpError
    | FailedToCreateDiscordPrivateChannel (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Evergreen.V116.Discord.HttpError
