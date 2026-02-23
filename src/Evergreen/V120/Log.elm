module Evergreen.V120.Log exposing (..)

import Effect.Http
import Evergreen.V120.Discord
import Evergreen.V120.Discord.Id
import Evergreen.V120.EmailAddress
import Evergreen.V120.Emoji
import Evergreen.V120.Id
import Evergreen.V120.Postmark


type Log
    = LoginEmail (Result Evergreen.V120.Postmark.SendEmailError ()) Evergreen.V120.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
    | ChangedUsers (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V120.Postmark.SendEmailError Evergreen.V120.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Emoji.Emoji Evergreen.V120.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Emoji.Emoji Evergreen.V120.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) Evergreen.V120.Id.ThreadRouteWithMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Emoji.Emoji Evergreen.V120.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) Evergreen.V120.Emoji.Emoji Evergreen.V120.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.Discord.HttpError
