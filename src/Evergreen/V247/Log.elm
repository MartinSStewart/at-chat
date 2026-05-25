module Evergreen.V247.Log exposing (..)

import Effect.Http
import Evergreen.V247.Discord
import Evergreen.V247.EmailAddress
import Evergreen.V247.Emoji
import Evergreen.V247.Id
import Evergreen.V247.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V247.Postmark.SendEmailError ()) Evergreen.V247.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
    | ChangedUsers (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V247.Postmark.SendEmailError Evergreen.V247.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji Evergreen.V247.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji Evergreen.V247.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji Evergreen.V247.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) Evergreen.V247.Emoji.EmojiOrCustomEmoji Evergreen.V247.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Evergreen.V247.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) Evergreen.V247.Id.ThreadRouteWithMaybeMessage Evergreen.V247.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) Evergreen.V247.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V247.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) Evergreen.V247.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V247.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
