module Evergreen.V148.Log exposing (..)

import Effect.Http
import Evergreen.V148.Discord
import Evergreen.V148.EmailAddress
import Evergreen.V148.Emoji
import Evergreen.V148.Id
import Evergreen.V148.Postmark


type Log
    = LoginEmail (Result Evergreen.V148.Postmark.SendEmailError ()) Evergreen.V148.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
    | ChangedUsers (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V148.Postmark.SendEmailError Evergreen.V148.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Emoji.Emoji Evergreen.V148.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Emoji.Emoji Evergreen.V148.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Emoji.Emoji Evergreen.V148.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) Evergreen.V148.Emoji.Emoji Evergreen.V148.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) Evergreen.V148.Id.ThreadRouteWithMaybeMessage Evergreen.V148.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) Evergreen.V148.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V148.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
