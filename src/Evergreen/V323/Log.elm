module Evergreen.V323.Log exposing (..)

import Effect.Http
import Evergreen.V323.Discord
import Evergreen.V323.EmailAddress
import Evergreen.V323.Emoji
import Evergreen.V323.Id
import Evergreen.V323.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V323.Postmark.SendEmailError ()) Evergreen.V323.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V323.Postmark.SendEmailError ()) Evergreen.V323.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
    | ChangedUsers (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V323.Postmark.SendEmailError Evergreen.V323.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji Evergreen.V323.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji Evergreen.V323.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji Evergreen.V323.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji Evergreen.V323.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Evergreen.V323.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMaybeMessage Evergreen.V323.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) Evergreen.V323.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V323.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V323.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
