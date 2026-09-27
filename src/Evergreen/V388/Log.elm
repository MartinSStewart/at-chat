module Evergreen.V388.Log exposing (..)

import Effect.Http
import Evergreen.V388.Discord
import Evergreen.V388.EmailAddress
import Evergreen.V388.Emoji
import Evergreen.V388.Id
import Evergreen.V388.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V388.Postmark.SendEmailError ()) Evergreen.V388.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V388.Postmark.SendEmailError Evergreen.V388.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | ChangedUsers (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V388.Postmark.SendEmailError Evergreen.V388.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji Evergreen.V388.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji Evergreen.V388.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji Evergreen.V388.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) Evergreen.V388.Emoji.EmojiOrCustomEmoji Evergreen.V388.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Evergreen.V388.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) Evergreen.V388.Id.ThreadRouteWithMaybeMessage Evergreen.V388.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) Evergreen.V388.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V388.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V388.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
