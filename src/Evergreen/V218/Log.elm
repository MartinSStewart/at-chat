module Evergreen.V218.Log exposing (..)

import Effect.Http
import Evergreen.V218.Discord
import Evergreen.V218.EmailAddress
import Evergreen.V218.Emoji
import Evergreen.V218.Id
import Evergreen.V218.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V218.Postmark.SendEmailError ()) Evergreen.V218.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
    | ChangedUsers (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V218.Postmark.SendEmailError Evergreen.V218.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji Evergreen.V218.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji Evergreen.V218.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji Evergreen.V218.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji Evergreen.V218.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMaybeMessage Evergreen.V218.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) Evergreen.V218.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V218.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V218.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
