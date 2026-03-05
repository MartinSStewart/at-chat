module Evergreen.V135.Log exposing (..)

import Effect.Http
import Evergreen.V135.Discord
import Evergreen.V135.Discord.Id
import Evergreen.V135.EmailAddress
import Evergreen.V135.Emoji
import Evergreen.V135.Id
import Evergreen.V135.Postmark


type Log
    = LoginEmail (Result Evergreen.V135.Postmark.SendEmailError ()) Evergreen.V135.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
    | ChangedUsers (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V135.Postmark.SendEmailError Evergreen.V135.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Emoji.Emoji Evergreen.V135.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Emoji.Emoji Evergreen.V135.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Emoji.Emoji Evergreen.V135.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Emoji.Emoji Evergreen.V135.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMaybeMessage Evergreen.V135.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) Evergreen.V135.Discord.HttpError
