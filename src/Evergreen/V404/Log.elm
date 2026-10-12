module Evergreen.V404.Log exposing (..)

import Effect.Http
import Evergreen.V404.Discord
import Evergreen.V404.EmailAddress
import Evergreen.V404.Emoji
import Evergreen.V404.Id
import Evergreen.V404.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V404.Postmark.SendEmailError ()) Evergreen.V404.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V404.Postmark.SendEmailError Evergreen.V404.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    | ChangedUsers (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V404.Postmark.SendEmailError Evergreen.V404.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) Evergreen.V404.Id.ThreadRouteWithMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) Evergreen.V404.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) Evergreen.V404.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) Evergreen.V404.Id.ThreadRouteWithMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) Evergreen.V404.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) Evergreen.V404.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) Evergreen.V404.Id.ThreadRouteWithMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) Evergreen.V404.Emoji.EmojiOrCustomEmoji Evergreen.V404.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) Evergreen.V404.Emoji.EmojiOrCustomEmoji Evergreen.V404.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) Evergreen.V404.Id.ThreadRouteWithMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) Evergreen.V404.Emoji.EmojiOrCustomEmoji Evergreen.V404.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) Evergreen.V404.Emoji.EmojiOrCustomEmoji Evergreen.V404.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) Evergreen.V404.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) Evergreen.V404.Id.ThreadRouteWithMaybeMessage Evergreen.V404.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) Evergreen.V404.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V404.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) Evergreen.V404.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) Evergreen.V404.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) Evergreen.V404.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V404.Id.Id Evergreen.V404.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V404.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V404.Id.Id Evergreen.V404.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
