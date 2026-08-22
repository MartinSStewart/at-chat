module Evergreen.V360.Log exposing (..)

import Effect.Http
import Evergreen.V360.Discord
import Evergreen.V360.EmailAddress
import Evergreen.V360.Emoji
import Evergreen.V360.Id
import Evergreen.V360.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V360.Postmark.SendEmailError ()) Evergreen.V360.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V360.Postmark.SendEmailError Evergreen.V360.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    | ChangedUsers (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V360.Postmark.SendEmailError Evergreen.V360.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji Evergreen.V360.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji Evergreen.V360.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji Evergreen.V360.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) Evergreen.V360.Emoji.EmojiOrCustomEmoji Evergreen.V360.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Evergreen.V360.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) Evergreen.V360.Id.ThreadRouteWithMaybeMessage Evergreen.V360.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) Evergreen.V360.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V360.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V360.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
