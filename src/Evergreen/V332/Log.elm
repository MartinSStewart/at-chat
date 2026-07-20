module Evergreen.V332.Log exposing (..)

import Effect.Http
import Evergreen.V332.Discord
import Evergreen.V332.EmailAddress
import Evergreen.V332.Emoji
import Evergreen.V332.Id
import Evergreen.V332.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V332.Postmark.SendEmailError ()) Evergreen.V332.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V332.Postmark.SendEmailError ()) Evergreen.V332.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
    | ChangedUsers (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V332.Postmark.SendEmailError Evergreen.V332.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji Evergreen.V332.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji Evergreen.V332.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji Evergreen.V332.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) Evergreen.V332.Emoji.EmojiOrCustomEmoji Evergreen.V332.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Evergreen.V332.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) Evergreen.V332.Id.ThreadRouteWithMaybeMessage Evergreen.V332.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) Evergreen.V332.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V332.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) Evergreen.V332.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V332.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
