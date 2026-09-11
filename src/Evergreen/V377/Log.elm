module Evergreen.V377.Log exposing (..)

import Effect.Http
import Evergreen.V377.Discord
import Evergreen.V377.EmailAddress
import Evergreen.V377.Emoji
import Evergreen.V377.Id
import Evergreen.V377.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V377.Postmark.SendEmailError ()) Evergreen.V377.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V377.Postmark.SendEmailError Evergreen.V377.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | ChangedUsers (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V377.Postmark.SendEmailError Evergreen.V377.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji Evergreen.V377.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji Evergreen.V377.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji Evergreen.V377.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) Evergreen.V377.Emoji.EmojiOrCustomEmoji Evergreen.V377.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Evergreen.V377.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) Evergreen.V377.Id.ThreadRouteWithMaybeMessage Evergreen.V377.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) Evergreen.V377.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V377.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V377.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
