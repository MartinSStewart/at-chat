module Evergreen.V252.Log exposing (..)

import Effect.Http
import Evergreen.V252.Discord
import Evergreen.V252.EmailAddress
import Evergreen.V252.Emoji
import Evergreen.V252.Id
import Evergreen.V252.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V252.Postmark.SendEmailError ()) Evergreen.V252.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
    | ChangedUsers (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V252.Postmark.SendEmailError Evergreen.V252.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji Evergreen.V252.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji Evergreen.V252.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji Evergreen.V252.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) Evergreen.V252.Emoji.EmojiOrCustomEmoji Evergreen.V252.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Evergreen.V252.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) Evergreen.V252.Id.ThreadRouteWithMaybeMessage Evergreen.V252.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) Evergreen.V252.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V252.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) Evergreen.V252.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V252.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
