module Evergreen.V240.Log exposing (..)

import Effect.Http
import Evergreen.V240.Discord
import Evergreen.V240.EmailAddress
import Evergreen.V240.Emoji
import Evergreen.V240.Id
import Evergreen.V240.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V240.Postmark.SendEmailError ()) Evergreen.V240.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
    | ChangedUsers (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V240.Postmark.SendEmailError Evergreen.V240.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji Evergreen.V240.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji Evergreen.V240.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji Evergreen.V240.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) Evergreen.V240.Emoji.EmojiOrCustomEmoji Evergreen.V240.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) Evergreen.V240.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) Evergreen.V240.Id.ThreadRouteWithMaybeMessage Evergreen.V240.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) Evergreen.V240.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V240.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) Evergreen.V240.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V240.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
