module Evergreen.V392.Log exposing (..)

import Effect.Http
import Evergreen.V392.Discord
import Evergreen.V392.EmailAddress
import Evergreen.V392.Emoji
import Evergreen.V392.Id
import Evergreen.V392.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V392.Postmark.SendEmailError ()) Evergreen.V392.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V392.Postmark.SendEmailError Evergreen.V392.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | ChangedUsers (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V392.Postmark.SendEmailError Evergreen.V392.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji Evergreen.V392.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji Evergreen.V392.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji Evergreen.V392.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) Evergreen.V392.Emoji.EmojiOrCustomEmoji Evergreen.V392.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Evergreen.V392.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) Evergreen.V392.Id.ThreadRouteWithMaybeMessage Evergreen.V392.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) Evergreen.V392.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V392.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) Evergreen.V392.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V392.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
