module Evergreen.V243.Log exposing (..)

import Effect.Http
import Evergreen.V243.Discord
import Evergreen.V243.EmailAddress
import Evergreen.V243.Emoji
import Evergreen.V243.Id
import Evergreen.V243.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V243.Postmark.SendEmailError ()) Evergreen.V243.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
    | ChangedUsers (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V243.Postmark.SendEmailError Evergreen.V243.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji Evergreen.V243.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji Evergreen.V243.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji Evergreen.V243.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) Evergreen.V243.Emoji.EmojiOrCustomEmoji Evergreen.V243.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) Evergreen.V243.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) Evergreen.V243.Id.ThreadRouteWithMaybeMessage Evergreen.V243.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) Evergreen.V243.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V243.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) Evergreen.V243.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V243.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
