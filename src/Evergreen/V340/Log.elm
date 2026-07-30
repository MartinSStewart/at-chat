module Evergreen.V340.Log exposing (..)

import Effect.Http
import Evergreen.V340.Discord
import Evergreen.V340.EmailAddress
import Evergreen.V340.Emoji
import Evergreen.V340.Id
import Evergreen.V340.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V340.Postmark.SendEmailError ()) Evergreen.V340.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V340.Postmark.SendEmailError Evergreen.V340.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    | ChangedUsers (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V340.Postmark.SendEmailError Evergreen.V340.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji Evergreen.V340.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji Evergreen.V340.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji Evergreen.V340.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) Evergreen.V340.Emoji.EmojiOrCustomEmoji Evergreen.V340.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Evergreen.V340.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) Evergreen.V340.Id.ThreadRouteWithMaybeMessage Evergreen.V340.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) Evergreen.V340.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V340.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) Evergreen.V340.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V340.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
