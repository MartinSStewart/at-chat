module Evergreen.V363.Log exposing (..)

import Effect.Http
import Evergreen.V363.Discord
import Evergreen.V363.EmailAddress
import Evergreen.V363.Emoji
import Evergreen.V363.Id
import Evergreen.V363.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V363.Postmark.SendEmailError ()) Evergreen.V363.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V363.Postmark.SendEmailError Evergreen.V363.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    | ChangedUsers (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V363.Postmark.SendEmailError Evergreen.V363.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji Evergreen.V363.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji Evergreen.V363.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji Evergreen.V363.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) Evergreen.V363.Emoji.EmojiOrCustomEmoji Evergreen.V363.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Evergreen.V363.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) Evergreen.V363.Id.ThreadRouteWithMaybeMessage Evergreen.V363.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) Evergreen.V363.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V363.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V363.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
