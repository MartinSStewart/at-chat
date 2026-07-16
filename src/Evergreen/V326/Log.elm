module Evergreen.V326.Log exposing (..)

import Effect.Http
import Evergreen.V326.Discord
import Evergreen.V326.EmailAddress
import Evergreen.V326.Emoji
import Evergreen.V326.Id
import Evergreen.V326.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V326.Postmark.SendEmailError ()) Evergreen.V326.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V326.Postmark.SendEmailError ()) Evergreen.V326.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    | ChangedUsers (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V326.Postmark.SendEmailError Evergreen.V326.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji Evergreen.V326.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji Evergreen.V326.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji Evergreen.V326.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) Evergreen.V326.Emoji.EmojiOrCustomEmoji Evergreen.V326.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Evergreen.V326.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) Evergreen.V326.Id.ThreadRouteWithMaybeMessage Evergreen.V326.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) Evergreen.V326.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V326.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) Evergreen.V326.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V326.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
