module Evergreen.V397.Log exposing (..)

import Effect.Http
import Evergreen.V397.Discord
import Evergreen.V397.EmailAddress
import Evergreen.V397.Emoji
import Evergreen.V397.Id
import Evergreen.V397.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V397.Postmark.SendEmailError ()) Evergreen.V397.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V397.Postmark.SendEmailError Evergreen.V397.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | ChangedUsers (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V397.Postmark.SendEmailError Evergreen.V397.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji Evergreen.V397.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji Evergreen.V397.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji Evergreen.V397.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) Evergreen.V397.Emoji.EmojiOrCustomEmoji Evergreen.V397.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Evergreen.V397.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRouteWithMaybeMessage Evergreen.V397.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) Evergreen.V397.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V397.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V397.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
