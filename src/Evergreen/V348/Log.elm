module Evergreen.V348.Log exposing (..)

import Effect.Http
import Evergreen.V348.Discord
import Evergreen.V348.EmailAddress
import Evergreen.V348.Emoji
import Evergreen.V348.Id
import Evergreen.V348.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V348.Postmark.SendEmailError ()) Evergreen.V348.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V348.Postmark.SendEmailError Evergreen.V348.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    | ChangedUsers (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V348.Postmark.SendEmailError Evergreen.V348.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji Evergreen.V348.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji Evergreen.V348.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji Evergreen.V348.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) Evergreen.V348.Emoji.EmojiOrCustomEmoji Evergreen.V348.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Evergreen.V348.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) Evergreen.V348.Id.ThreadRouteWithMaybeMessage Evergreen.V348.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) Evergreen.V348.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V348.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) Evergreen.V348.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V348.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
