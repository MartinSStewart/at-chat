module Evergreen.V357.Log exposing (..)

import Effect.Http
import Evergreen.V357.Discord
import Evergreen.V357.EmailAddress
import Evergreen.V357.Emoji
import Evergreen.V357.Id
import Evergreen.V357.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V357.Postmark.SendEmailError ()) Evergreen.V357.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V357.Postmark.SendEmailError Evergreen.V357.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | ChangedUsers (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V357.Postmark.SendEmailError Evergreen.V357.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji Evergreen.V357.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji Evergreen.V357.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji Evergreen.V357.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) Evergreen.V357.Emoji.EmojiOrCustomEmoji Evergreen.V357.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Evergreen.V357.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) Evergreen.V357.Id.ThreadRouteWithMaybeMessage Evergreen.V357.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) Evergreen.V357.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V357.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V357.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
