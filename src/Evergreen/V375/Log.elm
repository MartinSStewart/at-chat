module Evergreen.V375.Log exposing (..)

import Effect.Http
import Evergreen.V375.Discord
import Evergreen.V375.EmailAddress
import Evergreen.V375.Emoji
import Evergreen.V375.Id
import Evergreen.V375.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V375.Postmark.SendEmailError ()) Evergreen.V375.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V375.Postmark.SendEmailError Evergreen.V375.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | ChangedUsers (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V375.Postmark.SendEmailError Evergreen.V375.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji Evergreen.V375.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji Evergreen.V375.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji Evergreen.V375.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) Evergreen.V375.Emoji.EmojiOrCustomEmoji Evergreen.V375.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Evergreen.V375.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) Evergreen.V375.Id.ThreadRouteWithMaybeMessage Evergreen.V375.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) Evergreen.V375.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V375.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V375.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
