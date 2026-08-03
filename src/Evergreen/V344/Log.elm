module Evergreen.V344.Log exposing (..)

import Effect.Http
import Evergreen.V344.Discord
import Evergreen.V344.EmailAddress
import Evergreen.V344.Emoji
import Evergreen.V344.Id
import Evergreen.V344.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V344.Postmark.SendEmailError ()) Evergreen.V344.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V344.Postmark.SendEmailError Evergreen.V344.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
    | ChangedUsers (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V344.Postmark.SendEmailError Evergreen.V344.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji Evergreen.V344.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji Evergreen.V344.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji Evergreen.V344.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) Evergreen.V344.Emoji.EmojiOrCustomEmoji Evergreen.V344.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) Evergreen.V344.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) Evergreen.V344.Id.ThreadRouteWithMaybeMessage Evergreen.V344.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) Evergreen.V344.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V344.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) Evergreen.V344.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V344.Id.Id Evergreen.V344.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V344.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V344.Id.Id Evergreen.V344.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
