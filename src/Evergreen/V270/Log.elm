module Evergreen.V270.Log exposing (..)

import Effect.Http
import Evergreen.V270.Discord
import Evergreen.V270.EmailAddress
import Evergreen.V270.Emoji
import Evergreen.V270.Id
import Evergreen.V270.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V270.Postmark.SendEmailError ()) Evergreen.V270.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
    | ChangedUsers (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V270.Postmark.SendEmailError Evergreen.V270.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji Evergreen.V270.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji Evergreen.V270.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji Evergreen.V270.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) Evergreen.V270.Emoji.EmojiOrCustomEmoji Evergreen.V270.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Evergreen.V270.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) Evergreen.V270.Id.ThreadRouteWithMaybeMessage Evergreen.V270.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) Evergreen.V270.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V270.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) Evergreen.V270.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V270.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
