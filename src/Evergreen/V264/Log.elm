module Evergreen.V264.Log exposing (..)

import Effect.Http
import Evergreen.V264.Discord
import Evergreen.V264.EmailAddress
import Evergreen.V264.Emoji
import Evergreen.V264.Id
import Evergreen.V264.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V264.Postmark.SendEmailError ()) Evergreen.V264.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
    | ChangedUsers (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V264.Postmark.SendEmailError Evergreen.V264.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji Evergreen.V264.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji Evergreen.V264.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji Evergreen.V264.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) Evergreen.V264.Emoji.EmojiOrCustomEmoji Evergreen.V264.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Evergreen.V264.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) Evergreen.V264.Id.ThreadRouteWithMaybeMessage Evergreen.V264.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) Evergreen.V264.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V264.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) Evergreen.V264.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V264.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
