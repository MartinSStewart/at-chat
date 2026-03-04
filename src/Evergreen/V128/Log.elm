module Evergreen.V128.Log exposing (..)

import Effect.Http
import Evergreen.V128.Discord
import Evergreen.V128.Discord.Id
import Evergreen.V128.EmailAddress
import Evergreen.V128.Emoji
import Evergreen.V128.Id
import Evergreen.V128.Postmark


type Log
    = LoginEmail (Result Evergreen.V128.Postmark.SendEmailError ()) Evergreen.V128.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
    | ChangedUsers (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V128.Postmark.SendEmailError Evergreen.V128.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Emoji.Emoji Evergreen.V128.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Emoji.Emoji Evergreen.V128.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Emoji.Emoji Evergreen.V128.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) Evergreen.V128.Emoji.Emoji Evergreen.V128.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) Evergreen.V128.Id.ThreadRouteWithMaybeMessage Evergreen.V128.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) Evergreen.V128.Discord.HttpError
