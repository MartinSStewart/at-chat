module Evergreen.V263.Log exposing (..)

import Effect.Http
import Evergreen.V263.Discord
import Evergreen.V263.EmailAddress
import Evergreen.V263.Emoji
import Evergreen.V263.Id
import Evergreen.V263.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V263.Postmark.SendEmailError ()) Evergreen.V263.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
    | ChangedUsers (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V263.Postmark.SendEmailError Evergreen.V263.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji Evergreen.V263.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji Evergreen.V263.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji Evergreen.V263.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) Evergreen.V263.Emoji.EmojiOrCustomEmoji Evergreen.V263.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Evergreen.V263.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) Evergreen.V263.Id.ThreadRouteWithMaybeMessage Evergreen.V263.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) Evergreen.V263.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V263.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) Evergreen.V263.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V263.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
