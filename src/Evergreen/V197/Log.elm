module Evergreen.V197.Log exposing (..)

import Effect.Http
import Evergreen.V197.Discord
import Evergreen.V197.EmailAddress
import Evergreen.V197.Emoji
import Evergreen.V197.Id
import Evergreen.V197.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V197.Postmark.SendEmailError ()) Evergreen.V197.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
    | ChangedUsers (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V197.Postmark.SendEmailError Evergreen.V197.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Emoji.Emoji Evergreen.V197.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Emoji.Emoji Evergreen.V197.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Emoji.Emoji Evergreen.V197.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) Evergreen.V197.Emoji.Emoji Evergreen.V197.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) Evergreen.V197.Id.ThreadRouteWithMaybeMessage Evergreen.V197.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) Evergreen.V197.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V197.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) Evergreen.V197.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V197.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
