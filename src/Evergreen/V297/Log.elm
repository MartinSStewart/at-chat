module Evergreen.V297.Log exposing (..)

import Effect.Http
import Evergreen.V297.Discord
import Evergreen.V297.EmailAddress
import Evergreen.V297.Emoji
import Evergreen.V297.Id
import Evergreen.V297.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V297.Postmark.SendEmailError ()) Evergreen.V297.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V297.Postmark.SendEmailError ()) Evergreen.V297.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
    | ChangedUsers (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V297.Postmark.SendEmailError Evergreen.V297.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji Evergreen.V297.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji Evergreen.V297.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji Evergreen.V297.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) Evergreen.V297.Emoji.EmojiOrCustomEmoji Evergreen.V297.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Evergreen.V297.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) Evergreen.V297.Id.ThreadRouteWithMaybeMessage Evergreen.V297.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) Evergreen.V297.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V297.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) Evergreen.V297.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V297.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
