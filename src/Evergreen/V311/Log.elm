module Evergreen.V311.Log exposing (..)

import Effect.Http
import Evergreen.V311.Discord
import Evergreen.V311.EmailAddress
import Evergreen.V311.Emoji
import Evergreen.V311.Id
import Evergreen.V311.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V311.Postmark.SendEmailError ()) Evergreen.V311.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V311.Postmark.SendEmailError ()) Evergreen.V311.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
    | ChangedUsers (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V311.Postmark.SendEmailError Evergreen.V311.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji Evergreen.V311.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji Evergreen.V311.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji Evergreen.V311.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) Evergreen.V311.Emoji.EmojiOrCustomEmoji Evergreen.V311.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Evergreen.V311.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) Evergreen.V311.Id.ThreadRouteWithMaybeMessage Evergreen.V311.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) Evergreen.V311.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V311.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) Evergreen.V311.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V311.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
