module Evergreen.V401.Log exposing (..)

import Effect.Http
import Evergreen.V401.Discord
import Evergreen.V401.EmailAddress
import Evergreen.V401.Emoji
import Evergreen.V401.Id
import Evergreen.V401.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V401.Postmark.SendEmailError ()) Evergreen.V401.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V401.Postmark.SendEmailError Evergreen.V401.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | ChangedUsers (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V401.Postmark.SendEmailError Evergreen.V401.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji Evergreen.V401.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji Evergreen.V401.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji Evergreen.V401.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) Evergreen.V401.Emoji.EmojiOrCustomEmoji Evergreen.V401.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Evergreen.V401.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRouteWithMaybeMessage Evergreen.V401.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) Evergreen.V401.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V401.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V401.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
