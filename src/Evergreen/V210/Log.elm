module Evergreen.V210.Log exposing (..)

import Effect.Http
import Evergreen.V210.Discord
import Evergreen.V210.EmailAddress
import Evergreen.V210.Emoji
import Evergreen.V210.Id
import Evergreen.V210.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V210.Postmark.SendEmailError ()) Evergreen.V210.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
    | ChangedUsers (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V210.Postmark.SendEmailError Evergreen.V210.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji Evergreen.V210.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji Evergreen.V210.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji Evergreen.V210.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji Evergreen.V210.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMaybeMessage Evergreen.V210.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) Evergreen.V210.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V210.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V210.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
