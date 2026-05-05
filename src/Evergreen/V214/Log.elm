module Evergreen.V214.Log exposing (..)

import Effect.Http
import Evergreen.V214.Discord
import Evergreen.V214.EmailAddress
import Evergreen.V214.Emoji
import Evergreen.V214.Id
import Evergreen.V214.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V214.Postmark.SendEmailError ()) Evergreen.V214.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
    | ChangedUsers (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V214.Postmark.SendEmailError Evergreen.V214.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) Evergreen.V214.Id.ThreadRouteWithMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) Evergreen.V214.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) Evergreen.V214.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) Evergreen.V214.Id.ThreadRouteWithMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) Evergreen.V214.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) Evergreen.V214.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) Evergreen.V214.Id.ThreadRouteWithMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) Evergreen.V214.Emoji.EmojiOrCustomEmoji Evergreen.V214.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) Evergreen.V214.Emoji.EmojiOrCustomEmoji Evergreen.V214.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) Evergreen.V214.Id.ThreadRouteWithMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) Evergreen.V214.Emoji.EmojiOrCustomEmoji Evergreen.V214.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) Evergreen.V214.Emoji.EmojiOrCustomEmoji Evergreen.V214.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) Evergreen.V214.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) Evergreen.V214.Id.ThreadRouteWithMaybeMessage Evergreen.V214.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) Evergreen.V214.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V214.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) Evergreen.V214.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) Evergreen.V214.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V214.Id.Id Evergreen.V214.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V214.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V214.Id.Id Evergreen.V214.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
