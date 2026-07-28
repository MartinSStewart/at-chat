module Evergreen.V338.Log exposing (..)

import Effect.Http
import Evergreen.V338.Discord
import Evergreen.V338.EmailAddress
import Evergreen.V338.Emoji
import Evergreen.V338.Id
import Evergreen.V338.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V338.Postmark.SendEmailError ()) Evergreen.V338.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V338.Postmark.SendEmailError Evergreen.V338.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
    | ChangedUsers (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V338.Postmark.SendEmailError Evergreen.V338.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji Evergreen.V338.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji Evergreen.V338.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji Evergreen.V338.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) Evergreen.V338.Emoji.EmojiOrCustomEmoji Evergreen.V338.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Evergreen.V338.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) Evergreen.V338.Id.ThreadRouteWithMaybeMessage Evergreen.V338.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) Evergreen.V338.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V338.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) Evergreen.V338.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V338.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
