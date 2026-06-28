module Evergreen.V296.Log exposing (..)

import Effect.Http
import Evergreen.V296.Discord
import Evergreen.V296.EmailAddress
import Evergreen.V296.Emoji
import Evergreen.V296.Id
import Evergreen.V296.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V296.Postmark.SendEmailError ()) Evergreen.V296.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)
    | ChangedUsers (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V296.Postmark.SendEmailError Evergreen.V296.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji Evergreen.V296.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji Evergreen.V296.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji Evergreen.V296.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) Evergreen.V296.Emoji.EmojiOrCustomEmoji Evergreen.V296.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Evergreen.V296.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) Evergreen.V296.Id.ThreadRouteWithMaybeMessage Evergreen.V296.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) Evergreen.V296.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V296.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) Evergreen.V296.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V296.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
