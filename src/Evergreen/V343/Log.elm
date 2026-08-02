module Evergreen.V343.Log exposing (..)

import Effect.Http
import Evergreen.V343.Discord
import Evergreen.V343.EmailAddress
import Evergreen.V343.Emoji
import Evergreen.V343.Id
import Evergreen.V343.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V343.Postmark.SendEmailError ()) Evergreen.V343.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V343.Postmark.SendEmailError Evergreen.V343.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
    | ChangedUsers (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V343.Postmark.SendEmailError Evergreen.V343.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji Evergreen.V343.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji Evergreen.V343.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji Evergreen.V343.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) Evergreen.V343.Emoji.EmojiOrCustomEmoji Evergreen.V343.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Evergreen.V343.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) Evergreen.V343.Id.ThreadRouteWithMaybeMessage Evergreen.V343.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) Evergreen.V343.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V343.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) Evergreen.V343.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V343.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
