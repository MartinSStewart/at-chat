module Evergreen.V162.Log exposing (..)

import Effect.Http
import Evergreen.V162.Discord
import Evergreen.V162.EmailAddress
import Evergreen.V162.Emoji
import Evergreen.V162.Id
import Evergreen.V162.Postmark


type Log
    = LoginEmail (Result Evergreen.V162.Postmark.SendEmailError ()) Evergreen.V162.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
    | ChangedUsers (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V162.Postmark.SendEmailError Evergreen.V162.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) Evergreen.V162.Id.ThreadRouteWithMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) Evergreen.V162.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) Evergreen.V162.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) Evergreen.V162.Id.ThreadRouteWithMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) Evergreen.V162.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) Evergreen.V162.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) Evergreen.V162.Id.ThreadRouteWithMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) Evergreen.V162.Emoji.Emoji Evergreen.V162.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) Evergreen.V162.Emoji.Emoji Evergreen.V162.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) Evergreen.V162.Id.ThreadRouteWithMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) Evergreen.V162.Emoji.Emoji Evergreen.V162.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) Evergreen.V162.Emoji.Emoji Evergreen.V162.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) Evergreen.V162.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) Evergreen.V162.Id.ThreadRouteWithMaybeMessage Evergreen.V162.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) Evergreen.V162.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V162.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) Evergreen.V162.Discord.HttpError
