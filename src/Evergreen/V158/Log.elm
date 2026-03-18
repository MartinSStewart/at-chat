module Evergreen.V158.Log exposing (..)

import Effect.Http
import Evergreen.V158.Discord
import Evergreen.V158.EmailAddress
import Evergreen.V158.Emoji
import Evergreen.V158.Id
import Evergreen.V158.Postmark


type Log
    = LoginEmail (Result Evergreen.V158.Postmark.SendEmailError ()) Evergreen.V158.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
    | ChangedUsers (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V158.Postmark.SendEmailError Evergreen.V158.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Emoji.Emoji Evergreen.V158.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Emoji.Emoji Evergreen.V158.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Emoji.Emoji Evergreen.V158.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) Evergreen.V158.Emoji.Emoji Evergreen.V158.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) Evergreen.V158.Id.ThreadRouteWithMaybeMessage Evergreen.V158.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) Evergreen.V158.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V158.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) Evergreen.V158.Discord.HttpError
