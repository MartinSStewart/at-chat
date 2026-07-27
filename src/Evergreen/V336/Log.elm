module Evergreen.V336.Log exposing (..)

import Effect.Http
import Evergreen.V336.Discord
import Evergreen.V336.EmailAddress
import Evergreen.V336.Emoji
import Evergreen.V336.Id
import Evergreen.V336.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V336.Postmark.SendEmailError ()) Evergreen.V336.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V336.Postmark.SendEmailError Evergreen.V336.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
    | ChangedUsers (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V336.Postmark.SendEmailError Evergreen.V336.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji Evergreen.V336.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji Evergreen.V336.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji Evergreen.V336.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) Evergreen.V336.Emoji.EmojiOrCustomEmoji Evergreen.V336.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Evergreen.V336.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) Evergreen.V336.Id.ThreadRouteWithMaybeMessage Evergreen.V336.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) Evergreen.V336.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V336.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) Evergreen.V336.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V336.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
