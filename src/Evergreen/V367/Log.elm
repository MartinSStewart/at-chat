module Evergreen.V367.Log exposing (..)

import Effect.Http
import Evergreen.V367.Discord
import Evergreen.V367.EmailAddress
import Evergreen.V367.Emoji
import Evergreen.V367.Id
import Evergreen.V367.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V367.Postmark.SendEmailError ()) Evergreen.V367.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V367.Postmark.SendEmailError Evergreen.V367.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)
    | ChangedUsers (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V367.Postmark.SendEmailError Evergreen.V367.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji Evergreen.V367.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji Evergreen.V367.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji Evergreen.V367.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) Evergreen.V367.Emoji.EmojiOrCustomEmoji Evergreen.V367.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) Evergreen.V367.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) Evergreen.V367.Id.ThreadRouteWithMaybeMessage Evergreen.V367.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId) Evergreen.V367.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V367.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) Evergreen.V367.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V367.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
