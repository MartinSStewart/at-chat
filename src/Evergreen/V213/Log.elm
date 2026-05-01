module Evergreen.V213.Log exposing (..)

import Effect.Http
import Evergreen.V213.Discord
import Evergreen.V213.EmailAddress
import Evergreen.V213.Emoji
import Evergreen.V213.Id
import Evergreen.V213.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V213.Postmark.SendEmailError ()) Evergreen.V213.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)
    | ChangedUsers (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V213.Postmark.SendEmailError Evergreen.V213.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji Evergreen.V213.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji Evergreen.V213.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji Evergreen.V213.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji Evergreen.V213.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMaybeMessage Evergreen.V213.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) Evergreen.V213.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V213.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V213.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
