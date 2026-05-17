module Evergreen.V232.Log exposing (..)

import Effect.Http
import Evergreen.V232.Discord
import Evergreen.V232.EmailAddress
import Evergreen.V232.Emoji
import Evergreen.V232.Id
import Evergreen.V232.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V232.Postmark.SendEmailError ()) Evergreen.V232.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
    | ChangedUsers (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V232.Postmark.SendEmailError Evergreen.V232.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji Evergreen.V232.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji Evergreen.V232.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji Evergreen.V232.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) Evergreen.V232.Emoji.EmojiOrCustomEmoji Evergreen.V232.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) Evergreen.V232.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) Evergreen.V232.Id.ThreadRouteWithMaybeMessage Evergreen.V232.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) Evergreen.V232.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V232.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) Evergreen.V232.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V232.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
