module Evergreen.V346.Log exposing (..)

import Effect.Http
import Evergreen.V346.Discord
import Evergreen.V346.EmailAddress
import Evergreen.V346.Emoji
import Evergreen.V346.Id
import Evergreen.V346.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V346.Postmark.SendEmailError ()) Evergreen.V346.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V346.Postmark.SendEmailError Evergreen.V346.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    | ChangedUsers (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V346.Postmark.SendEmailError Evergreen.V346.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji Evergreen.V346.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji Evergreen.V346.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji Evergreen.V346.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) Evergreen.V346.Emoji.EmojiOrCustomEmoji Evergreen.V346.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Evergreen.V346.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) Evergreen.V346.Id.ThreadRouteWithMaybeMessage Evergreen.V346.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) Evergreen.V346.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V346.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) Evergreen.V346.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V346.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
