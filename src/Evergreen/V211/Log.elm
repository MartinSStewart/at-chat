module Evergreen.V211.Log exposing (..)

import Effect.Http
import Evergreen.V211.Discord
import Evergreen.V211.EmailAddress
import Evergreen.V211.Emoji
import Evergreen.V211.Id
import Evergreen.V211.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V211.Postmark.SendEmailError ()) Evergreen.V211.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
    | ChangedUsers (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V211.Postmark.SendEmailError Evergreen.V211.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) Evergreen.V211.Id.ThreadRouteWithMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) Evergreen.V211.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) Evergreen.V211.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) Evergreen.V211.Id.ThreadRouteWithMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) Evergreen.V211.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) Evergreen.V211.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) Evergreen.V211.Id.ThreadRouteWithMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) Evergreen.V211.Emoji.EmojiOrCustomEmoji Evergreen.V211.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) Evergreen.V211.Emoji.EmojiOrCustomEmoji Evergreen.V211.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) Evergreen.V211.Id.ThreadRouteWithMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) Evergreen.V211.Emoji.EmojiOrCustomEmoji Evergreen.V211.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) Evergreen.V211.Emoji.EmojiOrCustomEmoji Evergreen.V211.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) Evergreen.V211.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) Evergreen.V211.Id.ThreadRouteWithMaybeMessage Evergreen.V211.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) Evergreen.V211.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V211.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) Evergreen.V211.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) Evergreen.V211.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V211.Id.Id Evergreen.V211.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V211.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V211.Id.Id Evergreen.V211.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
