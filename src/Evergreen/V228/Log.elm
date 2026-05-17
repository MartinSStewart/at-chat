module Evergreen.V228.Log exposing (..)

import Effect.Http
import Evergreen.V228.Discord
import Evergreen.V228.EmailAddress
import Evergreen.V228.Emoji
import Evergreen.V228.Id
import Evergreen.V228.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V228.Postmark.SendEmailError ()) Evergreen.V228.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
    | ChangedUsers (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V228.Postmark.SendEmailError Evergreen.V228.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji Evergreen.V228.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji Evergreen.V228.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji Evergreen.V228.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) Evergreen.V228.Emoji.EmojiOrCustomEmoji Evergreen.V228.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) Evergreen.V228.Id.ThreadRouteWithMaybeMessage Evergreen.V228.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) Evergreen.V228.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V228.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V228.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
