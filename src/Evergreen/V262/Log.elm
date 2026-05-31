module Evergreen.V262.Log exposing (..)

import Effect.Http
import Evergreen.V262.Discord
import Evergreen.V262.EmailAddress
import Evergreen.V262.Emoji
import Evergreen.V262.Id
import Evergreen.V262.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V262.Postmark.SendEmailError ()) Evergreen.V262.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
    | ChangedUsers (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V262.Postmark.SendEmailError Evergreen.V262.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) Evergreen.V262.Id.ThreadRouteWithMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) Evergreen.V262.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) Evergreen.V262.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) Evergreen.V262.Id.ThreadRouteWithMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) Evergreen.V262.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) Evergreen.V262.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) Evergreen.V262.Id.ThreadRouteWithMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) Evergreen.V262.Emoji.EmojiOrCustomEmoji Evergreen.V262.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) Evergreen.V262.Emoji.EmojiOrCustomEmoji Evergreen.V262.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) Evergreen.V262.Id.ThreadRouteWithMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) Evergreen.V262.Emoji.EmojiOrCustomEmoji Evergreen.V262.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) Evergreen.V262.Emoji.EmojiOrCustomEmoji Evergreen.V262.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) Evergreen.V262.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) Evergreen.V262.Id.ThreadRouteWithMaybeMessage Evergreen.V262.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) Evergreen.V262.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V262.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) Evergreen.V262.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) Evergreen.V262.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V262.Id.Id Evergreen.V262.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V262.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V262.Id.Id Evergreen.V262.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
