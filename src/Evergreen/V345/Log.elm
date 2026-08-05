module Evergreen.V345.Log exposing (..)

import Effect.Http
import Evergreen.V345.Discord
import Evergreen.V345.EmailAddress
import Evergreen.V345.Emoji
import Evergreen.V345.Id
import Evergreen.V345.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V345.Postmark.SendEmailError ()) Evergreen.V345.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V345.Postmark.SendEmailError Evergreen.V345.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
    | ChangedUsers (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V345.Postmark.SendEmailError Evergreen.V345.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji Evergreen.V345.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji Evergreen.V345.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji Evergreen.V345.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) Evergreen.V345.Emoji.EmojiOrCustomEmoji Evergreen.V345.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Evergreen.V345.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) Evergreen.V345.Id.ThreadRouteWithMaybeMessage Evergreen.V345.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) Evergreen.V345.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V345.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) Evergreen.V345.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V345.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
