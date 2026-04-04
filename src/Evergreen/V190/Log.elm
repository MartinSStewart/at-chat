module Evergreen.V190.Log exposing (..)

import Effect.Http
import Evergreen.V190.Discord
import Evergreen.V190.EmailAddress
import Evergreen.V190.Emoji
import Evergreen.V190.Id
import Evergreen.V190.Postmark


type Log
    = LoginEmail (Result Evergreen.V190.Postmark.SendEmailError ()) Evergreen.V190.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
    | ChangedUsers (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V190.Postmark.SendEmailError Evergreen.V190.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Emoji.Emoji Evergreen.V190.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Emoji.Emoji Evergreen.V190.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Emoji.Emoji Evergreen.V190.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) Evergreen.V190.Emoji.Emoji Evergreen.V190.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) Evergreen.V190.Id.ThreadRouteWithMaybeMessage Evergreen.V190.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) Evergreen.V190.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V190.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) Evergreen.V190.Discord.HttpError
    | EmptyDiscordMessage String
