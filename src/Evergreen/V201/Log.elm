module Evergreen.V201.Log exposing (..)

import Effect.Http
import Evergreen.V201.Discord
import Evergreen.V201.EmailAddress
import Evergreen.V201.Emoji
import Evergreen.V201.Id
import Evergreen.V201.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V201.Postmark.SendEmailError ()) Evergreen.V201.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
    | ChangedUsers (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V201.Postmark.SendEmailError Evergreen.V201.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Emoji.Emoji Evergreen.V201.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Emoji.Emoji Evergreen.V201.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Emoji.Emoji Evergreen.V201.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Emoji.Emoji Evergreen.V201.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMaybeMessage Evergreen.V201.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) Evergreen.V201.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V201.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V201.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
