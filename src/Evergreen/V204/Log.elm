module Evergreen.V204.Log exposing (..)

import Effect.Http
import Evergreen.V204.Discord
import Evergreen.V204.EmailAddress
import Evergreen.V204.Emoji
import Evergreen.V204.Id
import Evergreen.V204.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V204.Postmark.SendEmailError ()) Evergreen.V204.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
    | ChangedUsers (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V204.Postmark.SendEmailError Evergreen.V204.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Emoji.Emoji Evergreen.V204.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Emoji.Emoji Evergreen.V204.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Emoji.Emoji Evergreen.V204.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Emoji.Emoji Evergreen.V204.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMaybeMessage Evergreen.V204.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) Evergreen.V204.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V204.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V204.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
