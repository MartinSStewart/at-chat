module Evergreen.V368.Log exposing (..)

import Effect.Http
import Evergreen.V368.Discord
import Evergreen.V368.EmailAddress
import Evergreen.V368.Emoji
import Evergreen.V368.Id
import Evergreen.V368.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V368.Postmark.SendEmailError ()) Evergreen.V368.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V368.Postmark.SendEmailError Evergreen.V368.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | ChangedUsers (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V368.Postmark.SendEmailError Evergreen.V368.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji Evergreen.V368.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji Evergreen.V368.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji Evergreen.V368.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) Evergreen.V368.Emoji.EmojiOrCustomEmoji Evergreen.V368.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Evergreen.V368.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) Evergreen.V368.Id.ThreadRouteWithMaybeMessage Evergreen.V368.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) Evergreen.V368.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V368.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V368.Id.Id Evergreen.V368.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V368.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V368.Id.Id Evergreen.V368.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
