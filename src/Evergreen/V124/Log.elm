module Evergreen.V124.Log exposing (..)

import Effect.Http
import Evergreen.V124.Discord
import Evergreen.V124.Discord.Id
import Evergreen.V124.EmailAddress
import Evergreen.V124.Emoji
import Evergreen.V124.Id
import Evergreen.V124.Postmark


type Log
    = LoginEmail (Result Evergreen.V124.Postmark.SendEmailError ()) Evergreen.V124.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    | ChangedUsers (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V124.Postmark.SendEmailError Evergreen.V124.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Emoji.Emoji Evergreen.V124.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Emoji.Emoji Evergreen.V124.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Emoji.Emoji Evergreen.V124.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) Evergreen.V124.Emoji.Emoji Evergreen.V124.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) Evergreen.V124.Id.ThreadRouteWithMaybeMessage Evergreen.V124.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) Evergreen.V124.Discord.HttpError
