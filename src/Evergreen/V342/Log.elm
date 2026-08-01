module Evergreen.V342.Log exposing (..)

import Effect.Http
import Evergreen.V342.Discord
import Evergreen.V342.EmailAddress
import Evergreen.V342.Emoji
import Evergreen.V342.Id
import Evergreen.V342.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V342.Postmark.SendEmailError ()) Evergreen.V342.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V342.Postmark.SendEmailError Evergreen.V342.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
    | ChangedUsers (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V342.Postmark.SendEmailError Evergreen.V342.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji Evergreen.V342.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji Evergreen.V342.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji Evergreen.V342.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) Evergreen.V342.Emoji.EmojiOrCustomEmoji Evergreen.V342.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Evergreen.V342.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) Evergreen.V342.Id.ThreadRouteWithMaybeMessage Evergreen.V342.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) Evergreen.V342.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V342.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) Evergreen.V342.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V342.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
