module Evergreen.V185.Log exposing (..)

import Effect.Http
import Evergreen.V185.Discord
import Evergreen.V185.EmailAddress
import Evergreen.V185.Emoji
import Evergreen.V185.Id
import Evergreen.V185.Postmark


type Log
    = LoginEmail (Result Evergreen.V185.Postmark.SendEmailError ()) Evergreen.V185.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
    | ChangedUsers (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V185.Postmark.SendEmailError Evergreen.V185.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Emoji.Emoji Evergreen.V185.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Emoji.Emoji Evergreen.V185.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Emoji.Emoji Evergreen.V185.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) Evergreen.V185.Emoji.Emoji Evergreen.V185.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) Evergreen.V185.Id.ThreadRouteWithMaybeMessage Evergreen.V185.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) Evergreen.V185.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V185.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) Evergreen.V185.Discord.HttpError
    | EmptyDiscordMessage String
