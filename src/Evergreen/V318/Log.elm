module Evergreen.V318.Log exposing (..)

import Effect.Http
import Evergreen.V318.Discord
import Evergreen.V318.EmailAddress
import Evergreen.V318.Emoji
import Evergreen.V318.Id
import Evergreen.V318.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V318.Postmark.SendEmailError ()) Evergreen.V318.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V318.Postmark.SendEmailError ()) Evergreen.V318.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)
    | ChangedUsers (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V318.Postmark.SendEmailError Evergreen.V318.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji Evergreen.V318.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji Evergreen.V318.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji Evergreen.V318.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) Evergreen.V318.Emoji.EmojiOrCustomEmoji Evergreen.V318.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Evergreen.V318.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) Evergreen.V318.Id.ThreadRouteWithMaybeMessage Evergreen.V318.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) Evergreen.V318.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V318.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) Evergreen.V318.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V318.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
