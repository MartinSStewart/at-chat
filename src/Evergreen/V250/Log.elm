module Evergreen.V250.Log exposing (..)

import Effect.Http
import Evergreen.V250.Discord
import Evergreen.V250.EmailAddress
import Evergreen.V250.Emoji
import Evergreen.V250.Id
import Evergreen.V250.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V250.Postmark.SendEmailError ()) Evergreen.V250.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
    | ChangedUsers (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V250.Postmark.SendEmailError Evergreen.V250.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji Evergreen.V250.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji Evergreen.V250.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji Evergreen.V250.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) Evergreen.V250.Emoji.EmojiOrCustomEmoji Evergreen.V250.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Evergreen.V250.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) Evergreen.V250.Id.ThreadRouteWithMaybeMessage Evergreen.V250.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) Evergreen.V250.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V250.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) Evergreen.V250.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V250.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
