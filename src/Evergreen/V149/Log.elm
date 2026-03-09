module Evergreen.V149.Log exposing (..)

import Effect.Http
import Evergreen.V149.Discord
import Evergreen.V149.EmailAddress
import Evergreen.V149.Emoji
import Evergreen.V149.Id
import Evergreen.V149.Postmark


type Log
    = LoginEmail (Result Evergreen.V149.Postmark.SendEmailError ()) Evergreen.V149.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
    | ChangedUsers (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V149.Postmark.SendEmailError Evergreen.V149.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Emoji.Emoji Evergreen.V149.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Emoji.Emoji Evergreen.V149.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Emoji.Emoji Evergreen.V149.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) Evergreen.V149.Emoji.Emoji Evergreen.V149.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) Evergreen.V149.Id.ThreadRouteWithMaybeMessage Evergreen.V149.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) Evergreen.V149.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V149.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
