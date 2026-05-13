module Evergreen.V215.Log exposing (..)

import Effect.Http
import Evergreen.V215.Discord
import Evergreen.V215.EmailAddress
import Evergreen.V215.Emoji
import Evergreen.V215.Id
import Evergreen.V215.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V215.Postmark.SendEmailError ()) Evergreen.V215.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
    | ChangedUsers (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V215.Postmark.SendEmailError Evergreen.V215.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji Evergreen.V215.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji Evergreen.V215.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji Evergreen.V215.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji Evergreen.V215.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMaybeMessage Evergreen.V215.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) Evergreen.V215.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V215.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V215.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
