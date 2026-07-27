module Evergreen.V335.Log exposing (..)

import Effect.Http
import Evergreen.V335.Discord
import Evergreen.V335.EmailAddress
import Evergreen.V335.Emoji
import Evergreen.V335.Id
import Evergreen.V335.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V335.Postmark.SendEmailError ()) Evergreen.V335.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V335.Postmark.SendEmailError Evergreen.V335.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
    | ChangedUsers (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V335.Postmark.SendEmailError Evergreen.V335.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji Evergreen.V335.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji Evergreen.V335.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji Evergreen.V335.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji Evergreen.V335.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Evergreen.V335.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMaybeMessage Evergreen.V335.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) Evergreen.V335.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V335.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V335.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
