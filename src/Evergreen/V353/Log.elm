module Evergreen.V353.Log exposing (..)

import Effect.Http
import Evergreen.V353.Discord
import Evergreen.V353.EmailAddress
import Evergreen.V353.Emoji
import Evergreen.V353.Id
import Evergreen.V353.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V353.Postmark.SendEmailError ()) Evergreen.V353.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V353.Postmark.SendEmailError Evergreen.V353.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    | ChangedUsers (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V353.Postmark.SendEmailError Evergreen.V353.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji Evergreen.V353.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji Evergreen.V353.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji Evergreen.V353.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) Evergreen.V353.Emoji.EmojiOrCustomEmoji Evergreen.V353.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Evergreen.V353.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) Evergreen.V353.Id.ThreadRouteWithMaybeMessage Evergreen.V353.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) Evergreen.V353.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V353.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V353.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
