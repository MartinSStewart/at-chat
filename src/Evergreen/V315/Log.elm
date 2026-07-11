module Evergreen.V315.Log exposing (..)

import Effect.Http
import Evergreen.V315.Discord
import Evergreen.V315.EmailAddress
import Evergreen.V315.Emoji
import Evergreen.V315.Id
import Evergreen.V315.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V315.Postmark.SendEmailError ()) Evergreen.V315.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V315.Postmark.SendEmailError ()) Evergreen.V315.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
    | ChangedUsers (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V315.Postmark.SendEmailError Evergreen.V315.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji Evergreen.V315.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji Evergreen.V315.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji Evergreen.V315.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) Evergreen.V315.Emoji.EmojiOrCustomEmoji Evergreen.V315.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Evergreen.V315.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) Evergreen.V315.Id.ThreadRouteWithMaybeMessage Evergreen.V315.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) Evergreen.V315.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V315.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) Evergreen.V315.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V315.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
