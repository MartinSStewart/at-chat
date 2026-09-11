module Evergreen.V378.Log exposing (..)

import Effect.Http
import Evergreen.V378.Discord
import Evergreen.V378.EmailAddress
import Evergreen.V378.Emoji
import Evergreen.V378.Id
import Evergreen.V378.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V378.Postmark.SendEmailError ()) Evergreen.V378.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V378.Postmark.SendEmailError Evergreen.V378.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | ChangedUsers (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V378.Postmark.SendEmailError Evergreen.V378.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji Evergreen.V378.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji Evergreen.V378.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji Evergreen.V378.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) Evergreen.V378.Emoji.EmojiOrCustomEmoji Evergreen.V378.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Evergreen.V378.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) Evergreen.V378.Id.ThreadRouteWithMaybeMessage Evergreen.V378.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) Evergreen.V378.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V378.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V378.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
