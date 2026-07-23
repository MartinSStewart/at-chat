module Evergreen.V333.Log exposing (..)

import Effect.Http
import Evergreen.V333.Discord
import Evergreen.V333.EmailAddress
import Evergreen.V333.Emoji
import Evergreen.V333.Id
import Evergreen.V333.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V333.Postmark.SendEmailError ()) Evergreen.V333.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V333.Postmark.SendEmailError ()) Evergreen.V333.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
    | ChangedUsers (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V333.Postmark.SendEmailError Evergreen.V333.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji Evergreen.V333.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji Evergreen.V333.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji Evergreen.V333.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) Evergreen.V333.Emoji.EmojiOrCustomEmoji Evergreen.V333.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Evergreen.V333.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) Evergreen.V333.Id.ThreadRouteWithMaybeMessage Evergreen.V333.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) Evergreen.V333.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V333.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) Evergreen.V333.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V333.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
