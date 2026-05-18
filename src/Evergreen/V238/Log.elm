module Evergreen.V238.Log exposing (..)

import Effect.Http
import Evergreen.V238.Discord
import Evergreen.V238.EmailAddress
import Evergreen.V238.Emoji
import Evergreen.V238.Id
import Evergreen.V238.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V238.Postmark.SendEmailError ()) Evergreen.V238.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
    | ChangedUsers (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V238.Postmark.SendEmailError Evergreen.V238.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji Evergreen.V238.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji Evergreen.V238.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji Evergreen.V238.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) Evergreen.V238.Emoji.EmojiOrCustomEmoji Evergreen.V238.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) Evergreen.V238.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) Evergreen.V238.Id.ThreadRouteWithMaybeMessage Evergreen.V238.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) Evergreen.V238.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V238.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) Evergreen.V238.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V238.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
