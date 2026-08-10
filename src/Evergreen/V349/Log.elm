module Evergreen.V349.Log exposing (..)

import Effect.Http
import Evergreen.V349.Discord
import Evergreen.V349.EmailAddress
import Evergreen.V349.Emoji
import Evergreen.V349.Id
import Evergreen.V349.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V349.Postmark.SendEmailError ()) Evergreen.V349.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V349.Postmark.SendEmailError Evergreen.V349.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    | ChangedUsers (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V349.Postmark.SendEmailError Evergreen.V349.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji Evergreen.V349.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji Evergreen.V349.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji Evergreen.V349.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) Evergreen.V349.Emoji.EmojiOrCustomEmoji Evergreen.V349.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Evergreen.V349.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) Evergreen.V349.Id.ThreadRouteWithMaybeMessage Evergreen.V349.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) Evergreen.V349.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V349.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) Evergreen.V349.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V349.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
