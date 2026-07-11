module Evergreen.V313.Log exposing (..)

import Effect.Http
import Evergreen.V313.Discord
import Evergreen.V313.EmailAddress
import Evergreen.V313.Emoji
import Evergreen.V313.Id
import Evergreen.V313.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V313.Postmark.SendEmailError ()) Evergreen.V313.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V313.Postmark.SendEmailError ()) Evergreen.V313.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
    | ChangedUsers (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V313.Postmark.SendEmailError Evergreen.V313.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji Evergreen.V313.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji Evergreen.V313.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji Evergreen.V313.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) Evergreen.V313.Emoji.EmojiOrCustomEmoji Evergreen.V313.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Evergreen.V313.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) Evergreen.V313.Id.ThreadRouteWithMaybeMessage Evergreen.V313.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) Evergreen.V313.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V313.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) Evergreen.V313.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V313.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
