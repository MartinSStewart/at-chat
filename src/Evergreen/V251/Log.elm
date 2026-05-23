module Evergreen.V251.Log exposing (..)

import Effect.Http
import Evergreen.V251.Discord
import Evergreen.V251.EmailAddress
import Evergreen.V251.Emoji
import Evergreen.V251.Id
import Evergreen.V251.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V251.Postmark.SendEmailError ()) Evergreen.V251.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
    | ChangedUsers (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V251.Postmark.SendEmailError Evergreen.V251.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji Evergreen.V251.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji Evergreen.V251.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji Evergreen.V251.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) Evergreen.V251.Emoji.EmojiOrCustomEmoji Evergreen.V251.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Evergreen.V251.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) Evergreen.V251.Id.ThreadRouteWithMaybeMessage Evergreen.V251.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) Evergreen.V251.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V251.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) Evergreen.V251.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V251.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
