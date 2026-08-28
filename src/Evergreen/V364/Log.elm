module Evergreen.V364.Log exposing (..)

import Effect.Http
import Evergreen.V364.Discord
import Evergreen.V364.EmailAddress
import Evergreen.V364.Emoji
import Evergreen.V364.Id
import Evergreen.V364.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V364.Postmark.SendEmailError ()) Evergreen.V364.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V364.Postmark.SendEmailError Evergreen.V364.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    | ChangedUsers (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V364.Postmark.SendEmailError Evergreen.V364.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji Evergreen.V364.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji Evergreen.V364.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji Evergreen.V364.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) Evergreen.V364.Emoji.EmojiOrCustomEmoji Evergreen.V364.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Evergreen.V364.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) Evergreen.V364.Id.ThreadRouteWithMaybeMessage Evergreen.V364.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) Evergreen.V364.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V364.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V364.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
