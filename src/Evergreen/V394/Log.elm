module Evergreen.V394.Log exposing (..)

import Effect.Http
import Evergreen.V394.Discord
import Evergreen.V394.EmailAddress
import Evergreen.V394.Emoji
import Evergreen.V394.Id
import Evergreen.V394.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V394.Postmark.SendEmailError ()) Evergreen.V394.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V394.Postmark.SendEmailError Evergreen.V394.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | ChangedUsers (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V394.Postmark.SendEmailError Evergreen.V394.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji Evergreen.V394.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji Evergreen.V394.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji Evergreen.V394.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) Evergreen.V394.Emoji.EmojiOrCustomEmoji Evergreen.V394.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Evergreen.V394.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) Evergreen.V394.Id.ThreadRouteWithMaybeMessage Evergreen.V394.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) Evergreen.V394.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V394.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V394.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
