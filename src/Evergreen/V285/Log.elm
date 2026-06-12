module Evergreen.V285.Log exposing (..)

import Effect.Http
import Evergreen.V285.Discord
import Evergreen.V285.EmailAddress
import Evergreen.V285.Emoji
import Evergreen.V285.Id
import Evergreen.V285.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V285.Postmark.SendEmailError ()) Evergreen.V285.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
    | ChangedUsers (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V285.Postmark.SendEmailError Evergreen.V285.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji Evergreen.V285.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji Evergreen.V285.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji Evergreen.V285.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) Evergreen.V285.Emoji.EmojiOrCustomEmoji Evergreen.V285.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Evergreen.V285.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) Evergreen.V285.Id.ThreadRouteWithMaybeMessage Evergreen.V285.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) Evergreen.V285.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V285.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) Evergreen.V285.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V285.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
