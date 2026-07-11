module Evergreen.V312.Log exposing (..)

import Effect.Http
import Evergreen.V312.Discord
import Evergreen.V312.EmailAddress
import Evergreen.V312.Emoji
import Evergreen.V312.Id
import Evergreen.V312.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V312.Postmark.SendEmailError ()) Evergreen.V312.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V312.Postmark.SendEmailError ()) Evergreen.V312.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
    | ChangedUsers (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V312.Postmark.SendEmailError Evergreen.V312.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji Evergreen.V312.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji Evergreen.V312.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji Evergreen.V312.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) Evergreen.V312.Emoji.EmojiOrCustomEmoji Evergreen.V312.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Evergreen.V312.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) Evergreen.V312.Id.ThreadRouteWithMaybeMessage Evergreen.V312.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) Evergreen.V312.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V312.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) Evergreen.V312.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V312.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
