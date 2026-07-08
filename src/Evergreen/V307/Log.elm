module Evergreen.V307.Log exposing (..)

import Effect.Http
import Evergreen.V307.Discord
import Evergreen.V307.EmailAddress
import Evergreen.V307.Emoji
import Evergreen.V307.Id
import Evergreen.V307.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V307.Postmark.SendEmailError ()) Evergreen.V307.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V307.Postmark.SendEmailError ()) Evergreen.V307.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    | ChangedUsers (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V307.Postmark.SendEmailError Evergreen.V307.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji Evergreen.V307.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji Evergreen.V307.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji Evergreen.V307.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) Evergreen.V307.Emoji.EmojiOrCustomEmoji Evergreen.V307.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Evergreen.V307.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) Evergreen.V307.Id.ThreadRouteWithMaybeMessage Evergreen.V307.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) Evergreen.V307.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V307.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) Evergreen.V307.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V307.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
