module Evergreen.V316.Log exposing (..)

import Effect.Http
import Evergreen.V316.Discord
import Evergreen.V316.EmailAddress
import Evergreen.V316.Emoji
import Evergreen.V316.Id
import Evergreen.V316.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V316.Postmark.SendEmailError ()) Evergreen.V316.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V316.Postmark.SendEmailError ()) Evergreen.V316.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
    | ChangedUsers (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V316.Postmark.SendEmailError Evergreen.V316.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji Evergreen.V316.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji Evergreen.V316.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji Evergreen.V316.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) Evergreen.V316.Emoji.EmojiOrCustomEmoji Evergreen.V316.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Evergreen.V316.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) Evergreen.V316.Id.ThreadRouteWithMaybeMessage Evergreen.V316.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) Evergreen.V316.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V316.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) Evergreen.V316.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V316.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
