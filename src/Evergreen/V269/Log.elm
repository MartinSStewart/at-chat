module Evergreen.V269.Log exposing (..)

import Effect.Http
import Evergreen.V269.Discord
import Evergreen.V269.EmailAddress
import Evergreen.V269.Emoji
import Evergreen.V269.Id
import Evergreen.V269.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V269.Postmark.SendEmailError ()) Evergreen.V269.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
    | ChangedUsers (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V269.Postmark.SendEmailError Evergreen.V269.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji Evergreen.V269.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji Evergreen.V269.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji Evergreen.V269.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) Evergreen.V269.Emoji.EmojiOrCustomEmoji Evergreen.V269.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Evergreen.V269.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) Evergreen.V269.Id.ThreadRouteWithMaybeMessage Evergreen.V269.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) Evergreen.V269.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V269.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) Evergreen.V269.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V269.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
