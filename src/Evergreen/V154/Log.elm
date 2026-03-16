module Evergreen.V154.Log exposing (..)

import Effect.Http
import Evergreen.V154.Discord
import Evergreen.V154.EmailAddress
import Evergreen.V154.Emoji
import Evergreen.V154.Id
import Evergreen.V154.Postmark


type Log
    = LoginEmail (Result Evergreen.V154.Postmark.SendEmailError ()) Evergreen.V154.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
    | ChangedUsers (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V154.Postmark.SendEmailError Evergreen.V154.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Emoji.Emoji Evergreen.V154.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Emoji.Emoji Evergreen.V154.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Emoji.Emoji Evergreen.V154.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Emoji.Emoji Evergreen.V154.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMaybeMessage Evergreen.V154.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) Evergreen.V154.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V154.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
