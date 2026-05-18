module Evergreen.V229.Log exposing (..)

import Effect.Http
import Evergreen.V229.Discord
import Evergreen.V229.EmailAddress
import Evergreen.V229.Emoji
import Evergreen.V229.Id
import Evergreen.V229.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V229.Postmark.SendEmailError ()) Evergreen.V229.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
    | ChangedUsers (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V229.Postmark.SendEmailError Evergreen.V229.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji Evergreen.V229.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji Evergreen.V229.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji Evergreen.V229.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) Evergreen.V229.Emoji.EmojiOrCustomEmoji Evergreen.V229.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) Evergreen.V229.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) Evergreen.V229.Id.ThreadRouteWithMaybeMessage Evergreen.V229.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) Evergreen.V229.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V229.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) Evergreen.V229.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V229.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
