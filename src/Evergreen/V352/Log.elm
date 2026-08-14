module Evergreen.V352.Log exposing (..)

import Effect.Http
import Evergreen.V352.Discord
import Evergreen.V352.EmailAddress
import Evergreen.V352.Emoji
import Evergreen.V352.Id
import Evergreen.V352.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V352.Postmark.SendEmailError ()) Evergreen.V352.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V352.Postmark.SendEmailError Evergreen.V352.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    | ChangedUsers (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V352.Postmark.SendEmailError Evergreen.V352.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji Evergreen.V352.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji Evergreen.V352.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji Evergreen.V352.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) Evergreen.V352.Emoji.EmojiOrCustomEmoji Evergreen.V352.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Evergreen.V352.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) Evergreen.V352.Id.ThreadRouteWithMaybeMessage Evergreen.V352.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) Evergreen.V352.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V352.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V352.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
