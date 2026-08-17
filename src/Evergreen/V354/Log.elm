module Evergreen.V354.Log exposing (..)

import Effect.Http
import Evergreen.V354.Discord
import Evergreen.V354.EmailAddress
import Evergreen.V354.Emoji
import Evergreen.V354.Id
import Evergreen.V354.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V354.Postmark.SendEmailError ()) Evergreen.V354.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V354.Postmark.SendEmailError Evergreen.V354.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    | ChangedUsers (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V354.Postmark.SendEmailError Evergreen.V354.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji Evergreen.V354.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji Evergreen.V354.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji Evergreen.V354.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) Evergreen.V354.Emoji.EmojiOrCustomEmoji Evergreen.V354.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Evergreen.V354.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) Evergreen.V354.Id.ThreadRouteWithMaybeMessage Evergreen.V354.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) Evergreen.V354.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V354.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V354.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
