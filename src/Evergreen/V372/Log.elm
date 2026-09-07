module Evergreen.V372.Log exposing (..)

import Effect.Http
import Evergreen.V372.Discord
import Evergreen.V372.EmailAddress
import Evergreen.V372.Emoji
import Evergreen.V372.Id
import Evergreen.V372.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V372.Postmark.SendEmailError ()) Evergreen.V372.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V372.Postmark.SendEmailError Evergreen.V372.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | ChangedUsers (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V372.Postmark.SendEmailError Evergreen.V372.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji Evergreen.V372.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji Evergreen.V372.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji Evergreen.V372.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) Evergreen.V372.Emoji.EmojiOrCustomEmoji Evergreen.V372.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Evergreen.V372.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) Evergreen.V372.Id.ThreadRouteWithMaybeMessage Evergreen.V372.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) Evergreen.V372.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V372.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V372.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
