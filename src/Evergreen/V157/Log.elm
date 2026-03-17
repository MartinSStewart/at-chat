module Evergreen.V157.Log exposing (..)

import Effect.Http
import Evergreen.V157.Discord
import Evergreen.V157.EmailAddress
import Evergreen.V157.Emoji
import Evergreen.V157.Id
import Evergreen.V157.Postmark


type Log
    = LoginEmail (Result Evergreen.V157.Postmark.SendEmailError ()) Evergreen.V157.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
    | ChangedUsers (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V157.Postmark.SendEmailError Evergreen.V157.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Emoji.Emoji Evergreen.V157.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Emoji.Emoji Evergreen.V157.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Emoji.Emoji Evergreen.V157.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) Evergreen.V157.Emoji.Emoji Evergreen.V157.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) Evergreen.V157.Id.ThreadRouteWithMaybeMessage Evergreen.V157.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) Evergreen.V157.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V157.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) Evergreen.V157.Discord.HttpError
