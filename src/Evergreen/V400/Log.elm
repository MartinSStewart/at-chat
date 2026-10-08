module Evergreen.V400.Log exposing (..)

import Effect.Http
import Evergreen.V400.Discord
import Evergreen.V400.EmailAddress
import Evergreen.V400.Emoji
import Evergreen.V400.Id
import Evergreen.V400.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V400.Postmark.SendEmailError ()) Evergreen.V400.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V400.Postmark.SendEmailError Evergreen.V400.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    | ChangedUsers (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V400.Postmark.SendEmailError Evergreen.V400.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) Evergreen.V400.Id.ThreadRouteWithMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) Evergreen.V400.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) Evergreen.V400.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) Evergreen.V400.Id.ThreadRouteWithMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) Evergreen.V400.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) Evergreen.V400.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) Evergreen.V400.Id.ThreadRouteWithMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) Evergreen.V400.Emoji.EmojiOrCustomEmoji Evergreen.V400.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) Evergreen.V400.Emoji.EmojiOrCustomEmoji Evergreen.V400.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) Evergreen.V400.Id.ThreadRouteWithMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) Evergreen.V400.Emoji.EmojiOrCustomEmoji Evergreen.V400.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) Evergreen.V400.Emoji.EmojiOrCustomEmoji Evergreen.V400.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) Evergreen.V400.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) Evergreen.V400.Id.ThreadRouteWithMaybeMessage Evergreen.V400.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) Evergreen.V400.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V400.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) Evergreen.V400.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) Evergreen.V400.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) Evergreen.V400.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V400.Id.Id Evergreen.V400.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V400.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V400.Id.Id Evergreen.V400.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
