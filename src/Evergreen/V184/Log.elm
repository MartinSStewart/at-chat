module Evergreen.V184.Log exposing (..)

import Effect.Http
import Evergreen.V184.Discord
import Evergreen.V184.EmailAddress
import Evergreen.V184.Emoji
import Evergreen.V184.Id
import Evergreen.V184.Postmark


type Log
    = LoginEmail (Result Evergreen.V184.Postmark.SendEmailError ()) Evergreen.V184.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
    | ChangedUsers (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V184.Postmark.SendEmailError Evergreen.V184.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Emoji.Emoji Evergreen.V184.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Emoji.Emoji Evergreen.V184.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Emoji.Emoji Evergreen.V184.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) Evergreen.V184.Emoji.Emoji Evergreen.V184.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) Evergreen.V184.Id.ThreadRouteWithMaybeMessage Evergreen.V184.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) Evergreen.V184.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V184.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) Evergreen.V184.Discord.HttpError
    | EmptyDiscordMessage String
