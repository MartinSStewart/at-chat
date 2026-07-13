module Evergreen.V317.Log exposing (..)

import Effect.Http
import Evergreen.V317.Discord
import Evergreen.V317.EmailAddress
import Evergreen.V317.Emoji
import Evergreen.V317.Id
import Evergreen.V317.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V317.Postmark.SendEmailError ()) Evergreen.V317.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V317.Postmark.SendEmailError ()) Evergreen.V317.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
    | ChangedUsers (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V317.Postmark.SendEmailError Evergreen.V317.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji Evergreen.V317.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji Evergreen.V317.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji Evergreen.V317.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) Evergreen.V317.Emoji.EmojiOrCustomEmoji Evergreen.V317.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Evergreen.V317.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) Evergreen.V317.Id.ThreadRouteWithMaybeMessage Evergreen.V317.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) Evergreen.V317.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V317.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) Evergreen.V317.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V317.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
