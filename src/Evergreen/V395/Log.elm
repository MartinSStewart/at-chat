module Evergreen.V395.Log exposing (..)

import Effect.Http
import Evergreen.V395.Discord
import Evergreen.V395.EmailAddress
import Evergreen.V395.Emoji
import Evergreen.V395.Id
import Evergreen.V395.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V395.Postmark.SendEmailError ()) Evergreen.V395.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V395.Postmark.SendEmailError Evergreen.V395.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | ChangedUsers (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V395.Postmark.SendEmailError Evergreen.V395.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji Evergreen.V395.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji Evergreen.V395.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji Evergreen.V395.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) Evergreen.V395.Emoji.EmojiOrCustomEmoji Evergreen.V395.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Evergreen.V395.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) Evergreen.V395.Id.ThreadRouteWithMaybeMessage Evergreen.V395.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) Evergreen.V395.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V395.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V395.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
