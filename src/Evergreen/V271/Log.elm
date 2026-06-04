module Evergreen.V271.Log exposing (..)

import Effect.Http
import Evergreen.V271.Discord
import Evergreen.V271.EmailAddress
import Evergreen.V271.Emoji
import Evergreen.V271.Id
import Evergreen.V271.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V271.Postmark.SendEmailError ()) Evergreen.V271.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
    | ChangedUsers (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V271.Postmark.SendEmailError Evergreen.V271.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji Evergreen.V271.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji Evergreen.V271.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji Evergreen.V271.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) Evergreen.V271.Emoji.EmojiOrCustomEmoji Evergreen.V271.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Evergreen.V271.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) Evergreen.V271.Id.ThreadRouteWithMaybeMessage Evergreen.V271.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) Evergreen.V271.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V271.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) Evergreen.V271.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V271.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
