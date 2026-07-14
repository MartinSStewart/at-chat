module Evergreen.V319.Log exposing (..)

import Effect.Http
import Evergreen.V319.Discord
import Evergreen.V319.EmailAddress
import Evergreen.V319.Emoji
import Evergreen.V319.Id
import Evergreen.V319.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V319.Postmark.SendEmailError ()) Evergreen.V319.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V319.Postmark.SendEmailError ()) Evergreen.V319.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | ChangedUsers (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V319.Postmark.SendEmailError Evergreen.V319.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji Evergreen.V319.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji Evergreen.V319.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji Evergreen.V319.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) Evergreen.V319.Emoji.EmojiOrCustomEmoji Evergreen.V319.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Evergreen.V319.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) Evergreen.V319.Id.ThreadRouteWithMaybeMessage Evergreen.V319.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) Evergreen.V319.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V319.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) Evergreen.V319.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V319.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
