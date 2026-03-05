module Evergreen.V134.Log exposing (..)

import Effect.Http
import Evergreen.V134.Discord
import Evergreen.V134.Discord.Id
import Evergreen.V134.EmailAddress
import Evergreen.V134.Emoji
import Evergreen.V134.Id
import Evergreen.V134.Postmark


type Log
    = LoginEmail (Result Evergreen.V134.Postmark.SendEmailError ()) Evergreen.V134.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    | ChangedUsers (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V134.Postmark.SendEmailError Evergreen.V134.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Emoji.Emoji Evergreen.V134.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Emoji.Emoji Evergreen.V134.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Emoji.Emoji Evergreen.V134.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Emoji.Emoji Evergreen.V134.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMaybeMessage Evergreen.V134.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) Evergreen.V134.Discord.HttpError
