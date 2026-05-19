module Evergreen.V239.Log exposing (..)

import Effect.Http
import Evergreen.V239.Discord
import Evergreen.V239.EmailAddress
import Evergreen.V239.Emoji
import Evergreen.V239.Id
import Evergreen.V239.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V239.Postmark.SendEmailError ()) Evergreen.V239.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
    | ChangedUsers (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V239.Postmark.SendEmailError Evergreen.V239.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji Evergreen.V239.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji Evergreen.V239.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji Evergreen.V239.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji Evergreen.V239.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMaybeMessage Evergreen.V239.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) Evergreen.V239.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V239.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V239.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
