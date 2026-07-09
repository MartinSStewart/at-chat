module Evergreen.V308.Log exposing (..)

import Effect.Http
import Evergreen.V308.Discord
import Evergreen.V308.EmailAddress
import Evergreen.V308.Emoji
import Evergreen.V308.Id
import Evergreen.V308.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V308.Postmark.SendEmailError ()) Evergreen.V308.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V308.Postmark.SendEmailError ()) Evergreen.V308.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
    | ChangedUsers (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V308.Postmark.SendEmailError Evergreen.V308.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji Evergreen.V308.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji Evergreen.V308.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji Evergreen.V308.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) Evergreen.V308.Emoji.EmojiOrCustomEmoji Evergreen.V308.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Evergreen.V308.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) Evergreen.V308.Id.ThreadRouteWithMaybeMessage Evergreen.V308.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) Evergreen.V308.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V308.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) Evergreen.V308.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V308.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
