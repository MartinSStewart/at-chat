module Evergreen.V196.Log exposing (..)

import Effect.Http
import Evergreen.V196.Discord
import Evergreen.V196.EmailAddress
import Evergreen.V196.Emoji
import Evergreen.V196.Id
import Evergreen.V196.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V196.Postmark.SendEmailError ()) Evergreen.V196.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
    | ChangedUsers (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V196.Postmark.SendEmailError Evergreen.V196.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) Evergreen.V196.Id.ThreadRouteWithMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) Evergreen.V196.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) Evergreen.V196.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) Evergreen.V196.Id.ThreadRouteWithMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) Evergreen.V196.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) Evergreen.V196.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) Evergreen.V196.Id.ThreadRouteWithMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) Evergreen.V196.Emoji.Emoji Evergreen.V196.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) Evergreen.V196.Emoji.Emoji Evergreen.V196.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) Evergreen.V196.Id.ThreadRouteWithMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) Evergreen.V196.Emoji.Emoji Evergreen.V196.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) Evergreen.V196.Emoji.Emoji Evergreen.V196.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) Evergreen.V196.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) Evergreen.V196.Id.ThreadRouteWithMaybeMessage Evergreen.V196.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) Evergreen.V196.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V196.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) Evergreen.V196.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) Evergreen.V196.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V196.Id.Id Evergreen.V196.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V196.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
