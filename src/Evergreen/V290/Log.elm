module Evergreen.V290.Log exposing (..)

import Effect.Http
import Evergreen.V290.Discord
import Evergreen.V290.EmailAddress
import Evergreen.V290.Emoji
import Evergreen.V290.Id
import Evergreen.V290.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V290.Postmark.SendEmailError ()) Evergreen.V290.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
    | ChangedUsers (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V290.Postmark.SendEmailError Evergreen.V290.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji Evergreen.V290.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji Evergreen.V290.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji Evergreen.V290.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) Evergreen.V290.Emoji.EmojiOrCustomEmoji Evergreen.V290.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Evergreen.V290.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) Evergreen.V290.Id.ThreadRouteWithMaybeMessage Evergreen.V290.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) Evergreen.V290.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V290.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) Evergreen.V290.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V290.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
