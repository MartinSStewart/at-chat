module Evergreen.V279.Log exposing (..)

import Effect.Http
import Evergreen.V279.Discord
import Evergreen.V279.EmailAddress
import Evergreen.V279.Emoji
import Evergreen.V279.Id
import Evergreen.V279.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V279.Postmark.SendEmailError ()) Evergreen.V279.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
    | ChangedUsers (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V279.Postmark.SendEmailError Evergreen.V279.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji Evergreen.V279.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji Evergreen.V279.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji Evergreen.V279.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) Evergreen.V279.Emoji.EmojiOrCustomEmoji Evergreen.V279.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Evergreen.V279.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) Evergreen.V279.Id.ThreadRouteWithMaybeMessage Evergreen.V279.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) Evergreen.V279.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V279.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) Evergreen.V279.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V279.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
