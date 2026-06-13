module Evergreen.V288.Log exposing (..)

import Effect.Http
import Evergreen.V288.Discord
import Evergreen.V288.EmailAddress
import Evergreen.V288.Emoji
import Evergreen.V288.Id
import Evergreen.V288.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V288.Postmark.SendEmailError ()) Evergreen.V288.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
    | ChangedUsers (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V288.Postmark.SendEmailError Evergreen.V288.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji Evergreen.V288.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji Evergreen.V288.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji Evergreen.V288.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) Evergreen.V288.Emoji.EmojiOrCustomEmoji Evergreen.V288.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Evergreen.V288.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) Evergreen.V288.Id.ThreadRouteWithMaybeMessage Evergreen.V288.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) Evergreen.V288.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V288.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) Evergreen.V288.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V288.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
