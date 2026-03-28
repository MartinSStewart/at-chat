module Evergreen.V176.Log exposing (..)

import Effect.Http
import Evergreen.V176.Discord
import Evergreen.V176.EmailAddress
import Evergreen.V176.Emoji
import Evergreen.V176.Id
import Evergreen.V176.Postmark


type Log
    = LoginEmail (Result Evergreen.V176.Postmark.SendEmailError ()) Evergreen.V176.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
    | ChangedUsers (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V176.Postmark.SendEmailError Evergreen.V176.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Emoji.Emoji Evergreen.V176.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Emoji.Emoji Evergreen.V176.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Emoji.Emoji Evergreen.V176.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Emoji.Emoji Evergreen.V176.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMaybeMessage Evergreen.V176.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) Evergreen.V176.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V176.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.Discord.HttpError
