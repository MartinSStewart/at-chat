module Evergreen.V166.Log exposing (..)

import Effect.Http
import Evergreen.V166.Discord
import Evergreen.V166.EmailAddress
import Evergreen.V166.Emoji
import Evergreen.V166.Id
import Evergreen.V166.Postmark


type Log
    = LoginEmail (Result Evergreen.V166.Postmark.SendEmailError ()) Evergreen.V166.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
    | ChangedUsers (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V166.Postmark.SendEmailError Evergreen.V166.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Emoji.Emoji Evergreen.V166.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Emoji.Emoji Evergreen.V166.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Emoji.Emoji Evergreen.V166.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) Evergreen.V166.Emoji.Emoji Evergreen.V166.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) Evergreen.V166.Id.ThreadRouteWithMaybeMessage Evergreen.V166.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) Evergreen.V166.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V166.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) Evergreen.V166.Discord.HttpError
