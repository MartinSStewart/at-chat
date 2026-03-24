module Evergreen.V169.Log exposing (..)

import Effect.Http
import Evergreen.V169.Discord
import Evergreen.V169.EmailAddress
import Evergreen.V169.Emoji
import Evergreen.V169.Id
import Evergreen.V169.Postmark


type Log
    = LoginEmail (Result Evergreen.V169.Postmark.SendEmailError ()) Evergreen.V169.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
    | ChangedUsers (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V169.Postmark.SendEmailError Evergreen.V169.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Emoji.Emoji Evergreen.V169.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Emoji.Emoji Evergreen.V169.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Emoji.Emoji Evergreen.V169.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Emoji.Emoji Evergreen.V169.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMaybeMessage Evergreen.V169.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) Evergreen.V169.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V169.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.Discord.HttpError
