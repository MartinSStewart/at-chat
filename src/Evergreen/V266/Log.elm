module Evergreen.V266.Log exposing (..)

import Effect.Http
import Evergreen.V266.Discord
import Evergreen.V266.EmailAddress
import Evergreen.V266.Emoji
import Evergreen.V266.Id
import Evergreen.V266.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V266.Postmark.SendEmailError ()) Evergreen.V266.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
    | ChangedUsers (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V266.Postmark.SendEmailError Evergreen.V266.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji Evergreen.V266.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji Evergreen.V266.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji Evergreen.V266.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) Evergreen.V266.Emoji.EmojiOrCustomEmoji Evergreen.V266.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Evergreen.V266.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) Evergreen.V266.Id.ThreadRouteWithMaybeMessage Evergreen.V266.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) Evergreen.V266.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V266.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) Evergreen.V266.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V266.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
