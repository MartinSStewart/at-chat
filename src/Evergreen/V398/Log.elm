module Evergreen.V398.Log exposing (..)

import Effect.Http
import Evergreen.V398.Discord
import Evergreen.V398.EmailAddress
import Evergreen.V398.Emoji
import Evergreen.V398.Id
import Evergreen.V398.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V398.Postmark.SendEmailError ()) Evergreen.V398.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V398.Postmark.SendEmailError Evergreen.V398.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | ChangedUsers (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V398.Postmark.SendEmailError Evergreen.V398.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji Evergreen.V398.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji Evergreen.V398.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji Evergreen.V398.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) Evergreen.V398.Emoji.EmojiOrCustomEmoji Evergreen.V398.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Evergreen.V398.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRouteWithMaybeMessage Evergreen.V398.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) Evergreen.V398.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V398.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V398.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
