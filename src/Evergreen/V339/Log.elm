module Evergreen.V339.Log exposing (..)

import Effect.Http
import Evergreen.V339.Discord
import Evergreen.V339.EmailAddress
import Evergreen.V339.Emoji
import Evergreen.V339.Id
import Evergreen.V339.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V339.Postmark.SendEmailError ()) Evergreen.V339.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V339.Postmark.SendEmailError Evergreen.V339.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
    | ChangedUsers (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V339.Postmark.SendEmailError Evergreen.V339.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji Evergreen.V339.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji Evergreen.V339.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji Evergreen.V339.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) Evergreen.V339.Emoji.EmojiOrCustomEmoji Evergreen.V339.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Evergreen.V339.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) Evergreen.V339.Id.ThreadRouteWithMaybeMessage Evergreen.V339.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) Evergreen.V339.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V339.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) Evergreen.V339.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V339.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
