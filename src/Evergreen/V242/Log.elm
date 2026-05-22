module Evergreen.V242.Log exposing (..)

import Effect.Http
import Evergreen.V242.Discord
import Evergreen.V242.EmailAddress
import Evergreen.V242.Emoji
import Evergreen.V242.Id
import Evergreen.V242.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V242.Postmark.SendEmailError ()) Evergreen.V242.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
    | ChangedUsers (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V242.Postmark.SendEmailError Evergreen.V242.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji Evergreen.V242.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji Evergreen.V242.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji Evergreen.V242.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) Evergreen.V242.Emoji.EmojiOrCustomEmoji Evergreen.V242.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) Evergreen.V242.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) Evergreen.V242.Id.ThreadRouteWithMaybeMessage Evergreen.V242.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) Evergreen.V242.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V242.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) Evergreen.V242.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V242.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
