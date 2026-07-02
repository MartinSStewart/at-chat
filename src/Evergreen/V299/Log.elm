module Evergreen.V299.Log exposing (..)

import Effect.Http
import Evergreen.V299.Discord
import Evergreen.V299.EmailAddress
import Evergreen.V299.Emoji
import Evergreen.V299.Id
import Evergreen.V299.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V299.Postmark.SendEmailError ()) Evergreen.V299.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V299.Postmark.SendEmailError ()) Evergreen.V299.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
    | ChangedUsers (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V299.Postmark.SendEmailError Evergreen.V299.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji Evergreen.V299.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji Evergreen.V299.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji Evergreen.V299.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) Evergreen.V299.Emoji.EmojiOrCustomEmoji Evergreen.V299.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Evergreen.V299.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) Evergreen.V299.Id.ThreadRouteWithMaybeMessage Evergreen.V299.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) Evergreen.V299.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V299.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) Evergreen.V299.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V299.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
