module Evergreen.V305.Log exposing (..)

import Effect.Http
import Evergreen.V305.Discord
import Evergreen.V305.EmailAddress
import Evergreen.V305.Emoji
import Evergreen.V305.Id
import Evergreen.V305.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V305.Postmark.SendEmailError ()) Evergreen.V305.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V305.Postmark.SendEmailError ()) Evergreen.V305.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
    | ChangedUsers (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V305.Postmark.SendEmailError Evergreen.V305.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) Evergreen.V305.Id.ThreadRouteWithMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) Evergreen.V305.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) Evergreen.V305.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) Evergreen.V305.Id.ThreadRouteWithMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) Evergreen.V305.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) Evergreen.V305.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) Evergreen.V305.Id.ThreadRouteWithMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) Evergreen.V305.Emoji.EmojiOrCustomEmoji Evergreen.V305.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) Evergreen.V305.Emoji.EmojiOrCustomEmoji Evergreen.V305.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) Evergreen.V305.Id.ThreadRouteWithMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) Evergreen.V305.Emoji.EmojiOrCustomEmoji Evergreen.V305.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) Evergreen.V305.Emoji.EmojiOrCustomEmoji Evergreen.V305.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) Evergreen.V305.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) Evergreen.V305.Id.ThreadRouteWithMaybeMessage Evergreen.V305.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) Evergreen.V305.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V305.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) Evergreen.V305.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) Evergreen.V305.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V305.Id.Id Evergreen.V305.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V305.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V305.Id.Id Evergreen.V305.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
