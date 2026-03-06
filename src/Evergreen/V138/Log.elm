module Evergreen.V138.Log exposing (..)

import Effect.Http
import Evergreen.V138.Discord
import Evergreen.V138.Discord.Id
import Evergreen.V138.EmailAddress
import Evergreen.V138.Emoji
import Evergreen.V138.Id
import Evergreen.V138.Postmark


type Log
    = LoginEmail (Result Evergreen.V138.Postmark.SendEmailError ()) Evergreen.V138.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
    | ChangedUsers (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V138.Postmark.SendEmailError Evergreen.V138.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Emoji.Emoji Evergreen.V138.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Emoji.Emoji Evergreen.V138.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Emoji.Emoji Evergreen.V138.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Emoji.Emoji Evergreen.V138.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMaybeMessage Evergreen.V138.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) Evergreen.V138.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V138.Discord.HttpError
    | FailedToParseDiscordWebsocket String
