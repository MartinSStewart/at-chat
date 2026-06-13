module Evergreen.V287.Log exposing (..)

import Effect.Http
import Evergreen.V287.Discord
import Evergreen.V287.EmailAddress
import Evergreen.V287.Emoji
import Evergreen.V287.Id
import Evergreen.V287.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V287.Postmark.SendEmailError ()) Evergreen.V287.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
    | ChangedUsers (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V287.Postmark.SendEmailError Evergreen.V287.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji Evergreen.V287.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji Evergreen.V287.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji Evergreen.V287.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) Evergreen.V287.Emoji.EmojiOrCustomEmoji Evergreen.V287.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Evergreen.V287.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) Evergreen.V287.Id.ThreadRouteWithMaybeMessage Evergreen.V287.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) Evergreen.V287.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V287.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) Evergreen.V287.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V287.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
