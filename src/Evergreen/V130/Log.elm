module Evergreen.V130.Log exposing (..)

import Effect.Http
import Evergreen.V130.Discord
import Evergreen.V130.Discord.Id
import Evergreen.V130.EmailAddress
import Evergreen.V130.Emoji
import Evergreen.V130.Id
import Evergreen.V130.Postmark


type Log
    = LoginEmail (Result Evergreen.V130.Postmark.SendEmailError ()) Evergreen.V130.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
    | ChangedUsers (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V130.Postmark.SendEmailError Evergreen.V130.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Emoji.Emoji Evergreen.V130.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Emoji.Emoji Evergreen.V130.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Emoji.Emoji Evergreen.V130.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) Evergreen.V130.Emoji.Emoji Evergreen.V130.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) Evergreen.V130.Id.ThreadRouteWithMaybeMessage Evergreen.V130.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) Evergreen.V130.Discord.HttpError
