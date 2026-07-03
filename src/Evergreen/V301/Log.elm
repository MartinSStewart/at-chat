module Evergreen.V301.Log exposing (..)

import Effect.Http
import Evergreen.V301.Discord
import Evergreen.V301.EmailAddress
import Evergreen.V301.Emoji
import Evergreen.V301.Id
import Evergreen.V301.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V301.Postmark.SendEmailError ()) Evergreen.V301.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V301.Postmark.SendEmailError ()) Evergreen.V301.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
    | ChangedUsers (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V301.Postmark.SendEmailError Evergreen.V301.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji Evergreen.V301.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji Evergreen.V301.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji Evergreen.V301.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) Evergreen.V301.Emoji.EmojiOrCustomEmoji Evergreen.V301.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Evergreen.V301.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) Evergreen.V301.Id.ThreadRouteWithMaybeMessage Evergreen.V301.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) Evergreen.V301.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V301.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) Evergreen.V301.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V301.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
