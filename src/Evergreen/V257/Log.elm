module Evergreen.V257.Log exposing (..)

import Effect.Http
import Evergreen.V257.Discord
import Evergreen.V257.EmailAddress
import Evergreen.V257.Emoji
import Evergreen.V257.Id
import Evergreen.V257.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V257.Postmark.SendEmailError ()) Evergreen.V257.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
    | ChangedUsers (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V257.Postmark.SendEmailError Evergreen.V257.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji Evergreen.V257.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji Evergreen.V257.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji Evergreen.V257.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) Evergreen.V257.Emoji.EmojiOrCustomEmoji Evergreen.V257.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Evergreen.V257.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) Evergreen.V257.Id.ThreadRouteWithMaybeMessage Evergreen.V257.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) Evergreen.V257.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V257.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V257.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
