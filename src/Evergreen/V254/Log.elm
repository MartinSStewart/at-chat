module Evergreen.V254.Log exposing (..)

import Effect.Http
import Evergreen.V254.Discord
import Evergreen.V254.EmailAddress
import Evergreen.V254.Emoji
import Evergreen.V254.Id
import Evergreen.V254.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V254.Postmark.SendEmailError ()) Evergreen.V254.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
    | ChangedUsers (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V254.Postmark.SendEmailError Evergreen.V254.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) Evergreen.V254.Id.ThreadRouteWithMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) Evergreen.V254.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) Evergreen.V254.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) Evergreen.V254.Id.ThreadRouteWithMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) Evergreen.V254.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) Evergreen.V254.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) Evergreen.V254.Id.ThreadRouteWithMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) Evergreen.V254.Emoji.EmojiOrCustomEmoji Evergreen.V254.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) Evergreen.V254.Emoji.EmojiOrCustomEmoji Evergreen.V254.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) Evergreen.V254.Id.ThreadRouteWithMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) Evergreen.V254.Emoji.EmojiOrCustomEmoji Evergreen.V254.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) Evergreen.V254.Emoji.EmojiOrCustomEmoji Evergreen.V254.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) Evergreen.V254.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) Evergreen.V254.Id.ThreadRouteWithMaybeMessage Evergreen.V254.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) Evergreen.V254.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V254.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) Evergreen.V254.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) Evergreen.V254.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V254.Id.Id Evergreen.V254.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V254.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V254.Id.Id Evergreen.V254.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
