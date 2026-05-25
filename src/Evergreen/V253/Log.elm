module Evergreen.V253.Log exposing (..)

import Effect.Http
import Evergreen.V253.Discord
import Evergreen.V253.EmailAddress
import Evergreen.V253.Emoji
import Evergreen.V253.Id
import Evergreen.V253.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V253.Postmark.SendEmailError ()) Evergreen.V253.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
    | ChangedUsers (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V253.Postmark.SendEmailError Evergreen.V253.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji Evergreen.V253.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji Evergreen.V253.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji Evergreen.V253.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) Evergreen.V253.Emoji.EmojiOrCustomEmoji Evergreen.V253.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Evergreen.V253.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) Evergreen.V253.Id.ThreadRouteWithMaybeMessage Evergreen.V253.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) Evergreen.V253.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V253.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) Evergreen.V253.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V253.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
