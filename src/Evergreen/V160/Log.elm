module Evergreen.V160.Log exposing (..)

import Effect.Http
import Evergreen.V160.Discord
import Evergreen.V160.EmailAddress
import Evergreen.V160.Emoji
import Evergreen.V160.Id
import Evergreen.V160.Postmark


type Log
    = LoginEmail (Result Evergreen.V160.Postmark.SendEmailError ()) Evergreen.V160.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
    | ChangedUsers (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V160.Postmark.SendEmailError Evergreen.V160.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Emoji.Emoji Evergreen.V160.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Emoji.Emoji Evergreen.V160.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Emoji.Emoji Evergreen.V160.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) Evergreen.V160.Emoji.Emoji Evergreen.V160.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) Evergreen.V160.Id.ThreadRouteWithMaybeMessage Evergreen.V160.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) Evergreen.V160.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V160.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) Evergreen.V160.Discord.HttpError
