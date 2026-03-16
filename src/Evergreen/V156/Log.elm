module Evergreen.V156.Log exposing (..)

import Effect.Http
import Evergreen.V156.Discord
import Evergreen.V156.EmailAddress
import Evergreen.V156.Emoji
import Evergreen.V156.Id
import Evergreen.V156.Postmark


type Log
    = LoginEmail (Result Evergreen.V156.Postmark.SendEmailError ()) Evergreen.V156.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
    | ChangedUsers (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V156.Postmark.SendEmailError Evergreen.V156.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Emoji.Emoji Evergreen.V156.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Emoji.Emoji Evergreen.V156.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Emoji.Emoji Evergreen.V156.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Emoji.Emoji Evergreen.V156.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMaybeMessage Evergreen.V156.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) Evergreen.V156.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V156.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
