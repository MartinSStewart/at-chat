module Evergreen.V187.Log exposing (..)

import Effect.Http
import Evergreen.V187.Discord
import Evergreen.V187.EmailAddress
import Evergreen.V187.Emoji
import Evergreen.V187.Id
import Evergreen.V187.Postmark


type Log
    = LoginEmail (Result Evergreen.V187.Postmark.SendEmailError ()) Evergreen.V187.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
    | ChangedUsers (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V187.Postmark.SendEmailError Evergreen.V187.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Emoji.Emoji Evergreen.V187.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Emoji.Emoji Evergreen.V187.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Emoji.Emoji Evergreen.V187.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) Evergreen.V187.Emoji.Emoji Evergreen.V187.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) Evergreen.V187.Id.ThreadRouteWithMaybeMessage Evergreen.V187.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) Evergreen.V187.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V187.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) Evergreen.V187.Discord.HttpError
    | EmptyDiscordMessage String
