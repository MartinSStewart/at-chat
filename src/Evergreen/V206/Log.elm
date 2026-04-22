module Evergreen.V206.Log exposing (..)

import Effect.Http
import Evergreen.V206.Discord
import Evergreen.V206.EmailAddress
import Evergreen.V206.Emoji
import Evergreen.V206.Id
import Evergreen.V206.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V206.Postmark.SendEmailError ()) Evergreen.V206.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
    | ChangedUsers (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V206.Postmark.SendEmailError Evergreen.V206.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Emoji.Emoji Evergreen.V206.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Emoji.Emoji Evergreen.V206.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Emoji.Emoji Evergreen.V206.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Emoji.Emoji Evergreen.V206.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMaybeMessage Evergreen.V206.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) Evergreen.V206.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V206.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V206.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
