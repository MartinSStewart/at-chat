module Evergreen.V223.Log exposing (..)

import Effect.Http
import Evergreen.V223.Discord
import Evergreen.V223.EmailAddress
import Evergreen.V223.Emoji
import Evergreen.V223.Id
import Evergreen.V223.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V223.Postmark.SendEmailError ()) Evergreen.V223.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
    | ChangedUsers (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V223.Postmark.SendEmailError Evergreen.V223.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) Evergreen.V223.Id.ThreadRouteWithMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) Evergreen.V223.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) Evergreen.V223.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) Evergreen.V223.Id.ThreadRouteWithMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) Evergreen.V223.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) Evergreen.V223.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) Evergreen.V223.Id.ThreadRouteWithMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) Evergreen.V223.Emoji.EmojiOrCustomEmoji Evergreen.V223.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) Evergreen.V223.Emoji.EmojiOrCustomEmoji Evergreen.V223.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) Evergreen.V223.Id.ThreadRouteWithMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) Evergreen.V223.Emoji.EmojiOrCustomEmoji Evergreen.V223.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) Evergreen.V223.Emoji.EmojiOrCustomEmoji Evergreen.V223.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) Evergreen.V223.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) Evergreen.V223.Id.ThreadRouteWithMaybeMessage Evergreen.V223.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) Evergreen.V223.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V223.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) Evergreen.V223.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) Evergreen.V223.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V223.Id.Id Evergreen.V223.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V223.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V223.Id.Id Evergreen.V223.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
