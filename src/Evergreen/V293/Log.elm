module Evergreen.V293.Log exposing (..)

import Effect.Http
import Evergreen.V293.Discord
import Evergreen.V293.EmailAddress
import Evergreen.V293.Emoji
import Evergreen.V293.Id
import Evergreen.V293.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V293.Postmark.SendEmailError ()) Evergreen.V293.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
    | ChangedUsers (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V293.Postmark.SendEmailError Evergreen.V293.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji Evergreen.V293.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji Evergreen.V293.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji Evergreen.V293.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) Evergreen.V293.Emoji.EmojiOrCustomEmoji Evergreen.V293.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Evergreen.V293.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) Evergreen.V293.Id.ThreadRouteWithMaybeMessage Evergreen.V293.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) Evergreen.V293.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V293.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) Evergreen.V293.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V293.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
