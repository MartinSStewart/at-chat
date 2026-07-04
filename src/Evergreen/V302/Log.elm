module Evergreen.V302.Log exposing (..)

import Effect.Http
import Evergreen.V302.Discord
import Evergreen.V302.EmailAddress
import Evergreen.V302.Emoji
import Evergreen.V302.Id
import Evergreen.V302.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V302.Postmark.SendEmailError ()) Evergreen.V302.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V302.Postmark.SendEmailError ()) Evergreen.V302.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
    | ChangedUsers (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V302.Postmark.SendEmailError Evergreen.V302.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji Evergreen.V302.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji Evergreen.V302.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji Evergreen.V302.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) Evergreen.V302.Emoji.EmojiOrCustomEmoji Evergreen.V302.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Evergreen.V302.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) Evergreen.V302.Id.ThreadRouteWithMaybeMessage Evergreen.V302.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) Evergreen.V302.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V302.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) Evergreen.V302.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V302.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
