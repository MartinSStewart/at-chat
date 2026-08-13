module Evergreen.V351.Log exposing (..)

import Effect.Http
import Evergreen.V351.Discord
import Evergreen.V351.EmailAddress
import Evergreen.V351.Emoji
import Evergreen.V351.Id
import Evergreen.V351.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V351.Postmark.SendEmailError ()) Evergreen.V351.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V351.Postmark.SendEmailError Evergreen.V351.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    | ChangedUsers (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V351.Postmark.SendEmailError Evergreen.V351.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji Evergreen.V351.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji Evergreen.V351.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji Evergreen.V351.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) Evergreen.V351.Emoji.EmojiOrCustomEmoji Evergreen.V351.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Evergreen.V351.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) Evergreen.V351.Id.ThreadRouteWithMaybeMessage Evergreen.V351.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) Evergreen.V351.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V351.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V351.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
