module Evergreen.V177.Log exposing (..)

import Effect.Http
import Evergreen.V177.Discord
import Evergreen.V177.EmailAddress
import Evergreen.V177.Emoji
import Evergreen.V177.Id
import Evergreen.V177.Postmark


type Log
    = LoginEmail (Result Evergreen.V177.Postmark.SendEmailError ()) Evergreen.V177.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
    | ChangedUsers (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V177.Postmark.SendEmailError Evergreen.V177.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Emoji.Emoji Evergreen.V177.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Emoji.Emoji Evergreen.V177.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Emoji.Emoji Evergreen.V177.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Emoji.Emoji Evergreen.V177.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMaybeMessage Evergreen.V177.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) Evergreen.V177.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V177.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.Discord.HttpError
