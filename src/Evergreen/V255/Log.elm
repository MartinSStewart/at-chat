module Evergreen.V255.Log exposing (..)

import Effect.Http
import Evergreen.V255.Discord
import Evergreen.V255.EmailAddress
import Evergreen.V255.Emoji
import Evergreen.V255.Id
import Evergreen.V255.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V255.Postmark.SendEmailError ()) Evergreen.V255.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
    | ChangedUsers (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V255.Postmark.SendEmailError Evergreen.V255.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji Evergreen.V255.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji Evergreen.V255.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji Evergreen.V255.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) Evergreen.V255.Emoji.EmojiOrCustomEmoji Evergreen.V255.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Evergreen.V255.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) Evergreen.V255.Id.ThreadRouteWithMaybeMessage Evergreen.V255.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) Evergreen.V255.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V255.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V255.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
