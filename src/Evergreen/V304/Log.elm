module Evergreen.V304.Log exposing (..)

import Effect.Http
import Evergreen.V304.Discord
import Evergreen.V304.EmailAddress
import Evergreen.V304.Emoji
import Evergreen.V304.Id
import Evergreen.V304.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V304.Postmark.SendEmailError ()) Evergreen.V304.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V304.Postmark.SendEmailError ()) Evergreen.V304.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
    | ChangedUsers (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V304.Postmark.SendEmailError Evergreen.V304.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji Evergreen.V304.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji Evergreen.V304.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji Evergreen.V304.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) Evergreen.V304.Emoji.EmojiOrCustomEmoji Evergreen.V304.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Evergreen.V304.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) Evergreen.V304.Id.ThreadRouteWithMaybeMessage Evergreen.V304.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) Evergreen.V304.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V304.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) Evergreen.V304.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V304.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
