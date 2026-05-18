module Evergreen.V236.Log exposing (..)

import Effect.Http
import Evergreen.V236.Discord
import Evergreen.V236.EmailAddress
import Evergreen.V236.Emoji
import Evergreen.V236.Id
import Evergreen.V236.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V236.Postmark.SendEmailError ()) Evergreen.V236.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
    | ChangedUsers (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V236.Postmark.SendEmailError Evergreen.V236.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji Evergreen.V236.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji Evergreen.V236.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji Evergreen.V236.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) Evergreen.V236.Emoji.EmojiOrCustomEmoji Evergreen.V236.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) Evergreen.V236.Id.ThreadRouteWithMaybeMessage Evergreen.V236.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) Evergreen.V236.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V236.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V236.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
