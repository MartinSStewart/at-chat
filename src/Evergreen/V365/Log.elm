module Evergreen.V365.Log exposing (..)

import Effect.Http
import Evergreen.V365.Discord
import Evergreen.V365.EmailAddress
import Evergreen.V365.Emoji
import Evergreen.V365.Id
import Evergreen.V365.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V365.Postmark.SendEmailError ()) Evergreen.V365.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V365.Postmark.SendEmailError Evergreen.V365.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    | ChangedUsers (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V365.Postmark.SendEmailError Evergreen.V365.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji Evergreen.V365.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji Evergreen.V365.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji Evergreen.V365.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) Evergreen.V365.Emoji.EmojiOrCustomEmoji Evergreen.V365.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Evergreen.V365.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) Evergreen.V365.Id.ThreadRouteWithMaybeMessage Evergreen.V365.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) Evergreen.V365.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V365.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V365.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
