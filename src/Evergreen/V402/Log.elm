module Evergreen.V402.Log exposing (..)

import Effect.Http
import Evergreen.V402.Discord
import Evergreen.V402.EmailAddress
import Evergreen.V402.Emoji
import Evergreen.V402.Id
import Evergreen.V402.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V402.Postmark.SendEmailError ()) Evergreen.V402.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V402.Postmark.SendEmailError Evergreen.V402.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | ChangedUsers (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V402.Postmark.SendEmailError Evergreen.V402.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji Evergreen.V402.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji Evergreen.V402.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji Evergreen.V402.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) Evergreen.V402.Emoji.EmojiOrCustomEmoji Evergreen.V402.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Evergreen.V402.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRouteWithMaybeMessage Evergreen.V402.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) Evergreen.V402.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V402.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V402.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
