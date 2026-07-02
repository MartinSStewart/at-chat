module Evergreen.V298.Log exposing (..)

import Effect.Http
import Evergreen.V298.Discord
import Evergreen.V298.EmailAddress
import Evergreen.V298.Emoji
import Evergreen.V298.Id
import Evergreen.V298.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V298.Postmark.SendEmailError ()) Evergreen.V298.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V298.Postmark.SendEmailError ()) Evergreen.V298.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
    | ChangedUsers (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V298.Postmark.SendEmailError Evergreen.V298.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji Evergreen.V298.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji Evergreen.V298.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji Evergreen.V298.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) Evergreen.V298.Emoji.EmojiOrCustomEmoji Evergreen.V298.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) Evergreen.V298.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) Evergreen.V298.Id.ThreadRouteWithMaybeMessage Evergreen.V298.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) Evergreen.V298.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V298.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) Evergreen.V298.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V298.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
