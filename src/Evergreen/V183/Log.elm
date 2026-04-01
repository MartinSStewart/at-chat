module Evergreen.V183.Log exposing (..)

import Effect.Http
import Evergreen.V183.Discord
import Evergreen.V183.EmailAddress
import Evergreen.V183.Emoji
import Evergreen.V183.Id
import Evergreen.V183.Postmark


type Log
    = LoginEmail (Result Evergreen.V183.Postmark.SendEmailError ()) Evergreen.V183.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
    | ChangedUsers (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V183.Postmark.SendEmailError Evergreen.V183.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Emoji.Emoji Evergreen.V183.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Emoji.Emoji Evergreen.V183.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Emoji.Emoji Evergreen.V183.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) Evergreen.V183.Emoji.Emoji Evergreen.V183.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) Evergreen.V183.Id.ThreadRouteWithMaybeMessage Evergreen.V183.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) Evergreen.V183.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V183.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) Evergreen.V183.Discord.HttpError
    | EmptyDiscordMessage String
