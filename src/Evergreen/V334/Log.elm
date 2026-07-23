module Evergreen.V334.Log exposing (..)

import Effect.Http
import Evergreen.V334.Discord
import Evergreen.V334.EmailAddress
import Evergreen.V334.Emoji
import Evergreen.V334.Id
import Evergreen.V334.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V334.Postmark.SendEmailError ()) Evergreen.V334.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V334.Postmark.SendEmailError Evergreen.V334.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
    | ChangedUsers (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V334.Postmark.SendEmailError Evergreen.V334.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) Evergreen.V334.Id.ThreadRouteWithMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) Evergreen.V334.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) Evergreen.V334.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) Evergreen.V334.Id.ThreadRouteWithMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) Evergreen.V334.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) Evergreen.V334.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) Evergreen.V334.Id.ThreadRouteWithMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) Evergreen.V334.Emoji.EmojiOrCustomEmoji Evergreen.V334.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) Evergreen.V334.Emoji.EmojiOrCustomEmoji Evergreen.V334.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) Evergreen.V334.Id.ThreadRouteWithMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) Evergreen.V334.Emoji.EmojiOrCustomEmoji Evergreen.V334.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) Evergreen.V334.Emoji.EmojiOrCustomEmoji Evergreen.V334.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) Evergreen.V334.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) Evergreen.V334.Id.ThreadRouteWithMaybeMessage Evergreen.V334.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) Evergreen.V334.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V334.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) Evergreen.V334.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) Evergreen.V334.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) Evergreen.V334.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V334.Id.Id Evergreen.V334.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V334.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V334.Id.Id Evergreen.V334.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedCloudflarePullOffer Effect.Http.Error
    | FailedCloudflareSessionCreate Effect.Http.Error
    | FailedCloudflarePushLocalTracks Effect.Http.Error
    | CloudflareCostExceeded Float Int
