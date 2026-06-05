module Evergreen.V277.Log exposing (..)

import Effect.Http
import Evergreen.V277.Discord
import Evergreen.V277.EmailAddress
import Evergreen.V277.Emoji
import Evergreen.V277.Id
import Evergreen.V277.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V277.Postmark.SendEmailError ()) Evergreen.V277.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
    | ChangedUsers (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V277.Postmark.SendEmailError Evergreen.V277.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji Evergreen.V277.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji Evergreen.V277.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji Evergreen.V277.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) Evergreen.V277.Emoji.EmojiOrCustomEmoji Evergreen.V277.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Evergreen.V277.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) Evergreen.V277.Id.ThreadRouteWithMaybeMessage Evergreen.V277.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) Evergreen.V277.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V277.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) Evergreen.V277.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V277.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
