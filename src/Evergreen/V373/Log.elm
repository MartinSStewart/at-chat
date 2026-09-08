module Evergreen.V373.Log exposing (..)

import Effect.Http
import Evergreen.V373.Discord
import Evergreen.V373.EmailAddress
import Evergreen.V373.Emoji
import Evergreen.V373.Id
import Evergreen.V373.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V373.Postmark.SendEmailError ()) Evergreen.V373.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V373.Postmark.SendEmailError Evergreen.V373.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | ChangedUsers (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V373.Postmark.SendEmailError Evergreen.V373.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji Evergreen.V373.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji Evergreen.V373.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji Evergreen.V373.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) Evergreen.V373.Emoji.EmojiOrCustomEmoji Evergreen.V373.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Evergreen.V373.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) Evergreen.V373.Id.ThreadRouteWithMaybeMessage Evergreen.V373.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) Evergreen.V373.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V373.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V373.Id.Id Evergreen.V373.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V373.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V373.Id.Id Evergreen.V373.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
