module Evergreen.V147.Log exposing (..)

import Effect.Http
import Evergreen.V147.Discord
import Evergreen.V147.EmailAddress
import Evergreen.V147.Emoji
import Evergreen.V147.Id
import Evergreen.V147.Postmark


type Log
    = LoginEmail (Result Evergreen.V147.Postmark.SendEmailError ()) Evergreen.V147.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
    | ChangedUsers (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V147.Postmark.SendEmailError Evergreen.V147.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Emoji.Emoji Evergreen.V147.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Emoji.Emoji Evergreen.V147.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Emoji.Emoji Evergreen.V147.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) Evergreen.V147.Emoji.Emoji Evergreen.V147.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) Evergreen.V147.Id.ThreadRouteWithMaybeMessage Evergreen.V147.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) Evergreen.V147.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V147.Discord.HttpError
    | FailedToParseDiscordWebsocket String
