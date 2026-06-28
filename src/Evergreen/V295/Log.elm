module Evergreen.V295.Log exposing (..)

import Effect.Http
import Evergreen.V295.Discord
import Evergreen.V295.EmailAddress
import Evergreen.V295.Emoji
import Evergreen.V295.Id
import Evergreen.V295.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V295.Postmark.SendEmailError ()) Evergreen.V295.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
    | ChangedUsers (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V295.Postmark.SendEmailError Evergreen.V295.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji Evergreen.V295.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji Evergreen.V295.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji Evergreen.V295.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) Evergreen.V295.Emoji.EmojiOrCustomEmoji Evergreen.V295.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Evergreen.V295.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) Evergreen.V295.Id.ThreadRouteWithMaybeMessage Evergreen.V295.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) Evergreen.V295.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V295.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) Evergreen.V295.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V295.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
