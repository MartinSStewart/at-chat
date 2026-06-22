module Evergreen.V294.Log exposing (..)

import Effect.Http
import Evergreen.V294.Discord
import Evergreen.V294.EmailAddress
import Evergreen.V294.Emoji
import Evergreen.V294.Id
import Evergreen.V294.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V294.Postmark.SendEmailError ()) Evergreen.V294.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
    | ChangedUsers (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V294.Postmark.SendEmailError Evergreen.V294.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji Evergreen.V294.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji Evergreen.V294.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji Evergreen.V294.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) Evergreen.V294.Emoji.EmojiOrCustomEmoji Evergreen.V294.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Evergreen.V294.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) Evergreen.V294.Id.ThreadRouteWithMaybeMessage Evergreen.V294.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) Evergreen.V294.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V294.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) Evergreen.V294.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V294.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
