module Evergreen.V273.Log exposing (..)

import Effect.Http
import Evergreen.V273.Discord
import Evergreen.V273.EmailAddress
import Evergreen.V273.Emoji
import Evergreen.V273.Id
import Evergreen.V273.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V273.Postmark.SendEmailError ()) Evergreen.V273.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
    | ChangedUsers (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V273.Postmark.SendEmailError Evergreen.V273.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji Evergreen.V273.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji Evergreen.V273.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji Evergreen.V273.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) Evergreen.V273.Emoji.EmojiOrCustomEmoji Evergreen.V273.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Evergreen.V273.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) Evergreen.V273.Id.ThreadRouteWithMaybeMessage Evergreen.V273.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) Evergreen.V273.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V273.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) Evergreen.V273.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V273.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
