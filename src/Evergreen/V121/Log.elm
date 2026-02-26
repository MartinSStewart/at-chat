module Evergreen.V121.Log exposing (..)

import Effect.Http
import Evergreen.V121.Discord
import Evergreen.V121.Discord.Id
import Evergreen.V121.EmailAddress
import Evergreen.V121.Emoji
import Evergreen.V121.Id
import Evergreen.V121.Postmark


type Log
    = LoginEmail (Result Evergreen.V121.Postmark.SendEmailError ()) Evergreen.V121.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
    | ChangedUsers (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V121.Postmark.SendEmailError Evergreen.V121.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) Evergreen.V121.Id.ThreadRouteWithMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) Evergreen.V121.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) Evergreen.V121.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) Evergreen.V121.Id.ThreadRouteWithMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) Evergreen.V121.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) Evergreen.V121.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) Evergreen.V121.Id.ThreadRouteWithMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) Evergreen.V121.Emoji.Emoji Evergreen.V121.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) Evergreen.V121.Emoji.Emoji Evergreen.V121.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) Evergreen.V121.Id.ThreadRouteWithMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) Evergreen.V121.Emoji.Emoji Evergreen.V121.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) Evergreen.V121.Emoji.Emoji Evergreen.V121.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) Evergreen.V121.Discord.HttpError
