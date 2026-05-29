module Evergreen.V261.Log exposing (..)

import Effect.Http
import Evergreen.V261.Discord
import Evergreen.V261.EmailAddress
import Evergreen.V261.Emoji
import Evergreen.V261.Id
import Evergreen.V261.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V261.Postmark.SendEmailError ()) Evergreen.V261.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
    | ChangedUsers (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V261.Postmark.SendEmailError Evergreen.V261.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji Evergreen.V261.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji Evergreen.V261.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji Evergreen.V261.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) Evergreen.V261.Emoji.EmojiOrCustomEmoji Evergreen.V261.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Evergreen.V261.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) Evergreen.V261.Id.ThreadRouteWithMaybeMessage Evergreen.V261.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) Evergreen.V261.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V261.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) Evergreen.V261.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V261.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
