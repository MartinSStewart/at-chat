module Evergreen.V122.Log exposing (..)

import Effect.Http
import Evergreen.V122.Discord
import Evergreen.V122.Discord.Id
import Evergreen.V122.EmailAddress
import Evergreen.V122.Emoji
import Evergreen.V122.Id
import Evergreen.V122.Postmark


type Log
    = LoginEmail (Result Evergreen.V122.Postmark.SendEmailError ()) Evergreen.V122.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
    | ChangedUsers (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V122.Postmark.SendEmailError Evergreen.V122.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Emoji.Emoji Evergreen.V122.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Emoji.Emoji Evergreen.V122.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Emoji.Emoji Evergreen.V122.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) Evergreen.V122.Emoji.Emoji Evergreen.V122.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) Evergreen.V122.Id.ThreadRouteWithMaybeMessage Evergreen.V122.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) Evergreen.V122.Discord.HttpError
