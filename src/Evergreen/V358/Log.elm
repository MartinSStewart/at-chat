module Evergreen.V358.Log exposing (..)

import Effect.Http
import Evergreen.V358.Discord
import Evergreen.V358.EmailAddress
import Evergreen.V358.Emoji
import Evergreen.V358.Id
import Evergreen.V358.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V358.Postmark.SendEmailError ()) Evergreen.V358.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V358.Postmark.SendEmailError Evergreen.V358.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
    | ChangedUsers (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V358.Postmark.SendEmailError Evergreen.V358.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji Evergreen.V358.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji Evergreen.V358.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji Evergreen.V358.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) Evergreen.V358.Emoji.EmojiOrCustomEmoji Evergreen.V358.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Evergreen.V358.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) Evergreen.V358.Id.ThreadRouteWithMaybeMessage Evergreen.V358.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) Evergreen.V358.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V358.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V358.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
