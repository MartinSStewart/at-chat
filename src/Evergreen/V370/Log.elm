module Evergreen.V370.Log exposing (..)

import Effect.Http
import Evergreen.V370.Discord
import Evergreen.V370.EmailAddress
import Evergreen.V370.Emoji
import Evergreen.V370.Id
import Evergreen.V370.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V370.Postmark.SendEmailError ()) Evergreen.V370.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V370.Postmark.SendEmailError Evergreen.V370.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | ChangedUsers (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V370.Postmark.SendEmailError Evergreen.V370.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji Evergreen.V370.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji Evergreen.V370.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji Evergreen.V370.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) Evergreen.V370.Emoji.EmojiOrCustomEmoji Evergreen.V370.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Evergreen.V370.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) Evergreen.V370.Id.ThreadRouteWithMaybeMessage Evergreen.V370.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) Evergreen.V370.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V370.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V370.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
