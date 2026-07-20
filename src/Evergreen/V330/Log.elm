module Evergreen.V330.Log exposing (..)

import Effect.Http
import Evergreen.V330.Discord
import Evergreen.V330.EmailAddress
import Evergreen.V330.Emoji
import Evergreen.V330.Id
import Evergreen.V330.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V330.Postmark.SendEmailError ()) Evergreen.V330.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V330.Postmark.SendEmailError ()) Evergreen.V330.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
    | ChangedUsers (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V330.Postmark.SendEmailError Evergreen.V330.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji Evergreen.V330.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji Evergreen.V330.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji Evergreen.V330.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) Evergreen.V330.Emoji.EmojiOrCustomEmoji Evergreen.V330.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Evergreen.V330.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) Evergreen.V330.Id.ThreadRouteWithMaybeMessage Evergreen.V330.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) Evergreen.V330.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V330.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) Evergreen.V330.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V330.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
