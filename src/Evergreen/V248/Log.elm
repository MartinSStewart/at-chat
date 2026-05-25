module Evergreen.V248.Log exposing (..)

import Effect.Http
import Evergreen.V248.Discord
import Evergreen.V248.EmailAddress
import Evergreen.V248.Emoji
import Evergreen.V248.Id
import Evergreen.V248.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V248.Postmark.SendEmailError ()) Evergreen.V248.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
    | ChangedUsers (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V248.Postmark.SendEmailError Evergreen.V248.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji Evergreen.V248.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji Evergreen.V248.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji Evergreen.V248.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) Evergreen.V248.Emoji.EmojiOrCustomEmoji Evergreen.V248.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Evergreen.V248.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) Evergreen.V248.Id.ThreadRouteWithMaybeMessage Evergreen.V248.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) Evergreen.V248.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V248.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) Evergreen.V248.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V248.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
