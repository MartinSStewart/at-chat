module Evergreen.V216.Log exposing (..)

import Effect.Http
import Evergreen.V216.Discord
import Evergreen.V216.EmailAddress
import Evergreen.V216.Emoji
import Evergreen.V216.Id
import Evergreen.V216.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V216.Postmark.SendEmailError ()) Evergreen.V216.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
    | ChangedUsers (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V216.Postmark.SendEmailError Evergreen.V216.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji Evergreen.V216.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji Evergreen.V216.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji Evergreen.V216.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji Evergreen.V216.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMaybeMessage Evergreen.V216.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) Evergreen.V216.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V216.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V216.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
