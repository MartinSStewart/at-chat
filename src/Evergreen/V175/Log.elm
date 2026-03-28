module Evergreen.V175.Log exposing (..)

import Effect.Http
import Evergreen.V175.Discord
import Evergreen.V175.EmailAddress
import Evergreen.V175.Emoji
import Evergreen.V175.Id
import Evergreen.V175.Postmark


type Log
    = LoginEmail (Result Evergreen.V175.Postmark.SendEmailError ()) Evergreen.V175.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
    | ChangedUsers (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V175.Postmark.SendEmailError Evergreen.V175.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Emoji.Emoji Evergreen.V175.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Emoji.Emoji Evergreen.V175.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Emoji.Emoji Evergreen.V175.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Emoji.Emoji Evergreen.V175.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMaybeMessage Evergreen.V175.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) Evergreen.V175.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V175.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.Discord.HttpError
