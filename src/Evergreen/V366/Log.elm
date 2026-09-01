module Evergreen.V366.Log exposing (..)

import Effect.Http
import Evergreen.V366.Discord
import Evergreen.V366.EmailAddress
import Evergreen.V366.Emoji
import Evergreen.V366.Id
import Evergreen.V366.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V366.Postmark.SendEmailError ()) Evergreen.V366.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V366.Postmark.SendEmailError Evergreen.V366.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    | ChangedUsers (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V366.Postmark.SendEmailError Evergreen.V366.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji Evergreen.V366.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji Evergreen.V366.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji Evergreen.V366.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) Evergreen.V366.Emoji.EmojiOrCustomEmoji Evergreen.V366.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Evergreen.V366.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) Evergreen.V366.Id.ThreadRouteWithMaybeMessage Evergreen.V366.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) Evergreen.V366.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V366.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V366.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
