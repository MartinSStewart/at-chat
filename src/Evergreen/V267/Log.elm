module Evergreen.V267.Log exposing (..)

import Effect.Http
import Evergreen.V267.Discord
import Evergreen.V267.EmailAddress
import Evergreen.V267.Emoji
import Evergreen.V267.Id
import Evergreen.V267.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V267.Postmark.SendEmailError ()) Evergreen.V267.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)
    | ChangedUsers (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V267.Postmark.SendEmailError Evergreen.V267.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji Evergreen.V267.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji Evergreen.V267.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji Evergreen.V267.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) Evergreen.V267.Emoji.EmojiOrCustomEmoji Evergreen.V267.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Evergreen.V267.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) Evergreen.V267.Id.ThreadRouteWithMaybeMessage Evergreen.V267.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) Evergreen.V267.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V267.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) Evergreen.V267.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V267.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
