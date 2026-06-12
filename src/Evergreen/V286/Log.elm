module Evergreen.V286.Log exposing (..)

import Effect.Http
import Evergreen.V286.Discord
import Evergreen.V286.EmailAddress
import Evergreen.V286.Emoji
import Evergreen.V286.Id
import Evergreen.V286.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V286.Postmark.SendEmailError ()) Evergreen.V286.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
    | ChangedUsers (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V286.Postmark.SendEmailError Evergreen.V286.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji Evergreen.V286.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji Evergreen.V286.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji Evergreen.V286.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) Evergreen.V286.Emoji.EmojiOrCustomEmoji Evergreen.V286.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Evergreen.V286.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) Evergreen.V286.Id.ThreadRouteWithMaybeMessage Evergreen.V286.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) Evergreen.V286.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V286.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) Evergreen.V286.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V286.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
