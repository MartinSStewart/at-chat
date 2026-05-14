module Evergreen.V217.Log exposing (..)

import Effect.Http
import Evergreen.V217.Discord
import Evergreen.V217.EmailAddress
import Evergreen.V217.Emoji
import Evergreen.V217.Id
import Evergreen.V217.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V217.Postmark.SendEmailError ()) Evergreen.V217.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
    | ChangedUsers (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V217.Postmark.SendEmailError Evergreen.V217.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji Evergreen.V217.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji Evergreen.V217.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji Evergreen.V217.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji Evergreen.V217.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMaybeMessage Evergreen.V217.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) Evergreen.V217.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V217.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V217.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
