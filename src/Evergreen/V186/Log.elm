module Evergreen.V186.Log exposing (..)

import Effect.Http
import Evergreen.V186.Discord
import Evergreen.V186.EmailAddress
import Evergreen.V186.Emoji
import Evergreen.V186.Id
import Evergreen.V186.Postmark


type Log
    = LoginEmail (Result Evergreen.V186.Postmark.SendEmailError ()) Evergreen.V186.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
    | ChangedUsers (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V186.Postmark.SendEmailError Evergreen.V186.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Emoji.Emoji Evergreen.V186.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Emoji.Emoji Evergreen.V186.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Emoji.Emoji Evergreen.V186.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) Evergreen.V186.Emoji.Emoji Evergreen.V186.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) Evergreen.V186.Id.ThreadRouteWithMaybeMessage Evergreen.V186.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) Evergreen.V186.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V186.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) Evergreen.V186.Discord.HttpError
    | EmptyDiscordMessage String
