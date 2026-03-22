module Evergreen.V167.Log exposing (..)

import Effect.Http
import Evergreen.V167.Discord
import Evergreen.V167.EmailAddress
import Evergreen.V167.Emoji
import Evergreen.V167.Id
import Evergreen.V167.Postmark


type Log
    = LoginEmail (Result Evergreen.V167.Postmark.SendEmailError ()) Evergreen.V167.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
    | ChangedUsers (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V167.Postmark.SendEmailError Evergreen.V167.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Emoji.Emoji Evergreen.V167.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Emoji.Emoji Evergreen.V167.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Emoji.Emoji Evergreen.V167.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) Evergreen.V167.Emoji.Emoji Evergreen.V167.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) Evergreen.V167.Id.ThreadRouteWithMaybeMessage Evergreen.V167.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) Evergreen.V167.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V167.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) Evergreen.V167.Discord.HttpError
