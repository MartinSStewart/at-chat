module Evergreen.V396.Log exposing (..)

import Effect.Http
import Evergreen.V396.Discord
import Evergreen.V396.EmailAddress
import Evergreen.V396.Emoji
import Evergreen.V396.Id
import Evergreen.V396.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V396.Postmark.SendEmailError ()) Evergreen.V396.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V396.Postmark.SendEmailError Evergreen.V396.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | ChangedUsers (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V396.Postmark.SendEmailError Evergreen.V396.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji Evergreen.V396.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji Evergreen.V396.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji Evergreen.V396.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) Evergreen.V396.Emoji.EmojiOrCustomEmoji Evergreen.V396.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Evergreen.V396.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) Evergreen.V396.Id.ThreadRouteWithMaybeMessage Evergreen.V396.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) Evergreen.V396.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V396.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V396.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
