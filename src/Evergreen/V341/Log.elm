module Evergreen.V341.Log exposing (..)

import Effect.Http
import Evergreen.V341.Discord
import Evergreen.V341.EmailAddress
import Evergreen.V341.Emoji
import Evergreen.V341.Id
import Evergreen.V341.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V341.Postmark.SendEmailError ()) Evergreen.V341.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V341.Postmark.SendEmailError Evergreen.V341.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    | ChangedUsers (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V341.Postmark.SendEmailError Evergreen.V341.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji Evergreen.V341.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji Evergreen.V341.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji Evergreen.V341.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) Evergreen.V341.Emoji.EmojiOrCustomEmoji Evergreen.V341.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Evergreen.V341.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) Evergreen.V341.Id.ThreadRouteWithMaybeMessage Evergreen.V341.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) Evergreen.V341.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V341.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) Evergreen.V341.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V341.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
