module Evergreen.V327.Log exposing (..)

import Effect.Http
import Evergreen.V327.Discord
import Evergreen.V327.EmailAddress
import Evergreen.V327.Emoji
import Evergreen.V327.Id
import Evergreen.V327.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V327.Postmark.SendEmailError ()) Evergreen.V327.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V327.Postmark.SendEmailError ()) Evergreen.V327.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
    | ChangedUsers (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V327.Postmark.SendEmailError Evergreen.V327.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji Evergreen.V327.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji Evergreen.V327.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji Evergreen.V327.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) Evergreen.V327.Emoji.EmojiOrCustomEmoji Evergreen.V327.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Evergreen.V327.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) Evergreen.V327.Id.ThreadRouteWithMaybeMessage Evergreen.V327.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) Evergreen.V327.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V327.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) Evergreen.V327.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V327.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
