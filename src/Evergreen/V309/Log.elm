module Evergreen.V309.Log exposing (..)

import Effect.Http
import Evergreen.V309.Discord
import Evergreen.V309.EmailAddress
import Evergreen.V309.Emoji
import Evergreen.V309.Id
import Evergreen.V309.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V309.Postmark.SendEmailError ()) Evergreen.V309.EmailAddress.EmailAddress
    | NotificationEmail (Result Evergreen.V309.Postmark.SendEmailError ()) Evergreen.V309.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
    | ChangedUsers (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V309.Postmark.SendEmailError Evergreen.V309.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji Evergreen.V309.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji Evergreen.V309.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji Evergreen.V309.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) Evergreen.V309.Emoji.EmojiOrCustomEmoji Evergreen.V309.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Evergreen.V309.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) Evergreen.V309.Id.ThreadRouteWithMaybeMessage Evergreen.V309.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) Evergreen.V309.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V309.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) Evergreen.V309.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V309.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
