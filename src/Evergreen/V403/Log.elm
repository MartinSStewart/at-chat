module Evergreen.V403.Log exposing (..)

import Effect.Http
import Evergreen.V403.Discord
import Evergreen.V403.EmailAddress
import Evergreen.V403.Emoji
import Evergreen.V403.Id
import Evergreen.V403.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V403.Postmark.SendEmailError ()) Evergreen.V403.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V403.Postmark.SendEmailError Evergreen.V403.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | ChangedUsers (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V403.Postmark.SendEmailError Evergreen.V403.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji Evergreen.V403.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji Evergreen.V403.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji Evergreen.V403.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) Evergreen.V403.Emoji.EmojiOrCustomEmoji Evergreen.V403.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Evergreen.V403.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRouteWithMaybeMessage Evergreen.V403.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) Evergreen.V403.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V403.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V403.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
