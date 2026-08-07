module Evergreen.V347.Log exposing (..)

import Effect.Http
import Evergreen.V347.Discord
import Evergreen.V347.EmailAddress
import Evergreen.V347.Emoji
import Evergreen.V347.Id
import Evergreen.V347.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V347.Postmark.SendEmailError ()) Evergreen.V347.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V347.Postmark.SendEmailError Evergreen.V347.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
    | ChangedUsers (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V347.Postmark.SendEmailError Evergreen.V347.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) Evergreen.V347.Id.ThreadRouteWithMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) Evergreen.V347.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) Evergreen.V347.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) Evergreen.V347.Id.ThreadRouteWithMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) Evergreen.V347.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) Evergreen.V347.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) Evergreen.V347.Id.ThreadRouteWithMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) Evergreen.V347.Emoji.EmojiOrCustomEmoji Evergreen.V347.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) Evergreen.V347.Emoji.EmojiOrCustomEmoji Evergreen.V347.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) Evergreen.V347.Id.ThreadRouteWithMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) Evergreen.V347.Emoji.EmojiOrCustomEmoji Evergreen.V347.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) Evergreen.V347.Emoji.EmojiOrCustomEmoji Evergreen.V347.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) Evergreen.V347.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) Evergreen.V347.Id.ThreadRouteWithMaybeMessage Evergreen.V347.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) Evergreen.V347.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V347.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) Evergreen.V347.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) Evergreen.V347.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) Evergreen.V347.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V347.Id.Id Evergreen.V347.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V347.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V347.Id.Id Evergreen.V347.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
