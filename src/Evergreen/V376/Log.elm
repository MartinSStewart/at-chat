module Evergreen.V376.Log exposing (..)

import Effect.Http
import Evergreen.V376.Discord
import Evergreen.V376.EmailAddress
import Evergreen.V376.Emoji
import Evergreen.V376.Id
import Evergreen.V376.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V376.Postmark.SendEmailError ()) Evergreen.V376.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V376.Postmark.SendEmailError Evergreen.V376.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | ChangedUsers (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V376.Postmark.SendEmailError Evergreen.V376.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji Evergreen.V376.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji Evergreen.V376.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji Evergreen.V376.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) Evergreen.V376.Emoji.EmojiOrCustomEmoji Evergreen.V376.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Evergreen.V376.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) Evergreen.V376.Id.ThreadRouteWithMaybeMessage Evergreen.V376.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) Evergreen.V376.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V376.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V376.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
