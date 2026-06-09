module Evergreen.V283.Log exposing (..)

import Effect.Http
import Evergreen.V283.Discord
import Evergreen.V283.EmailAddress
import Evergreen.V283.Emoji
import Evergreen.V283.Id
import Evergreen.V283.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V283.Postmark.SendEmailError ()) Evergreen.V283.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)
    | ChangedUsers (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V283.Postmark.SendEmailError Evergreen.V283.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji Evergreen.V283.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji Evergreen.V283.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji Evergreen.V283.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) Evergreen.V283.Emoji.EmojiOrCustomEmoji Evergreen.V283.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Evergreen.V283.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) Evergreen.V283.Id.ThreadRouteWithMaybeMessage Evergreen.V283.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) Evergreen.V283.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V283.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) Evergreen.V283.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V283.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
