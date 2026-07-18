module Evergreen.V328.Log exposing (..)

import Effect.Http
import Evergreen.V328.Discord
import Evergreen.V328.EmailAddress
import Evergreen.V328.Emoji
import Evergreen.V328.Id
import Evergreen.V328.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V328.Postmark.SendEmailError ()) Evergreen.V328.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V328.Postmark.SendEmailError ()) Evergreen.V328.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
    | ChangedUsers (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V328.Postmark.SendEmailError Evergreen.V328.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) Evergreen.V328.Id.ThreadRouteWithMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) Evergreen.V328.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) Evergreen.V328.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) Evergreen.V328.Id.ThreadRouteWithMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) Evergreen.V328.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) Evergreen.V328.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) Evergreen.V328.Id.ThreadRouteWithMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) Evergreen.V328.Emoji.EmojiOrCustomEmoji Evergreen.V328.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) Evergreen.V328.Emoji.EmojiOrCustomEmoji Evergreen.V328.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) Evergreen.V328.Id.ThreadRouteWithMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) Evergreen.V328.Emoji.EmojiOrCustomEmoji Evergreen.V328.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) Evergreen.V328.Emoji.EmojiOrCustomEmoji Evergreen.V328.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) Evergreen.V328.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) Evergreen.V328.Id.ThreadRouteWithMaybeMessage Evergreen.V328.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) Evergreen.V328.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V328.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) Evergreen.V328.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) Evergreen.V328.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V328.Id.Id Evergreen.V328.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V328.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V328.Id.Id Evergreen.V328.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
