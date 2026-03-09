module Evergreen.V146.Log exposing (..)

import Effect.Http
import Evergreen.V146.Discord
import Evergreen.V146.EmailAddress
import Evergreen.V146.Emoji
import Evergreen.V146.Id
import Evergreen.V146.Postmark


type Log
    = LoginEmail (Result Evergreen.V146.Postmark.SendEmailError ()) Evergreen.V146.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
    | ChangedUsers (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V146.Postmark.SendEmailError Evergreen.V146.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Emoji.Emoji Evergreen.V146.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Emoji.Emoji Evergreen.V146.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Emoji.Emoji Evergreen.V146.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) Evergreen.V146.Emoji.Emoji Evergreen.V146.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) Evergreen.V146.Id.ThreadRouteWithMaybeMessage Evergreen.V146.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) Evergreen.V146.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V146.Discord.HttpError
    | FailedToParseDiscordWebsocket String
