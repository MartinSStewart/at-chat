module Evergreen.V275.Log exposing (..)

import Effect.Http
import Evergreen.V275.Discord
import Evergreen.V275.EmailAddress
import Evergreen.V275.Emoji
import Evergreen.V275.Id
import Evergreen.V275.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V275.Postmark.SendEmailError ()) Evergreen.V275.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
    | ChangedUsers (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V275.Postmark.SendEmailError Evergreen.V275.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji Evergreen.V275.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji Evergreen.V275.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji Evergreen.V275.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) Evergreen.V275.Emoji.EmojiOrCustomEmoji Evergreen.V275.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Evergreen.V275.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) Evergreen.V275.Id.ThreadRouteWithMaybeMessage Evergreen.V275.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) Evergreen.V275.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V275.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) Evergreen.V275.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V275.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
