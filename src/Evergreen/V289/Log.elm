module Evergreen.V289.Log exposing (..)

import Effect.Http
import Evergreen.V289.Discord
import Evergreen.V289.EmailAddress
import Evergreen.V289.Emoji
import Evergreen.V289.Id
import Evergreen.V289.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V289.Postmark.SendEmailError ()) Evergreen.V289.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
    | ChangedUsers (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V289.Postmark.SendEmailError Evergreen.V289.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji Evergreen.V289.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji Evergreen.V289.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji Evergreen.V289.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) Evergreen.V289.Emoji.EmojiOrCustomEmoji Evergreen.V289.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Evergreen.V289.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) Evergreen.V289.Id.ThreadRouteWithMaybeMessage Evergreen.V289.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) Evergreen.V289.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V289.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) Evergreen.V289.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V289.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
