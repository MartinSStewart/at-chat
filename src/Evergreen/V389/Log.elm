module Evergreen.V389.Log exposing (..)

import Effect.Http
import Evergreen.V389.Discord
import Evergreen.V389.EmailAddress
import Evergreen.V389.Emoji
import Evergreen.V389.Id
import Evergreen.V389.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V389.Postmark.SendEmailError ()) Evergreen.V389.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V389.Postmark.SendEmailError Evergreen.V389.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | ChangedUsers (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V389.Postmark.SendEmailError Evergreen.V389.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji Evergreen.V389.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji Evergreen.V389.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji Evergreen.V389.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) Evergreen.V389.Emoji.EmojiOrCustomEmoji Evergreen.V389.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Evergreen.V389.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) Evergreen.V389.Id.ThreadRouteWithMaybeMessage Evergreen.V389.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) Evergreen.V389.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V389.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V389.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
