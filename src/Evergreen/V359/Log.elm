module Evergreen.V359.Log exposing (..)

import Effect.Http
import Evergreen.V359.Discord
import Evergreen.V359.EmailAddress
import Evergreen.V359.Emoji
import Evergreen.V359.Id
import Evergreen.V359.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V359.Postmark.SendEmailError ()) Evergreen.V359.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V359.Postmark.SendEmailError Evergreen.V359.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    | ChangedUsers (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V359.Postmark.SendEmailError Evergreen.V359.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji Evergreen.V359.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji Evergreen.V359.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji Evergreen.V359.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) Evergreen.V359.Emoji.EmojiOrCustomEmoji Evergreen.V359.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Evergreen.V359.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) Evergreen.V359.Id.ThreadRouteWithMaybeMessage Evergreen.V359.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) Evergreen.V359.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V359.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V359.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
