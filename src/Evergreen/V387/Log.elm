module Evergreen.V387.Log exposing (..)

import Effect.Http
import Evergreen.V387.Discord
import Evergreen.V387.EmailAddress
import Evergreen.V387.Emoji
import Evergreen.V387.Id
import Evergreen.V387.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V387.Postmark.SendEmailError ()) Evergreen.V387.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V387.Postmark.SendEmailError Evergreen.V387.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | ChangedUsers (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V387.Postmark.SendEmailError Evergreen.V387.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji Evergreen.V387.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji Evergreen.V387.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji Evergreen.V387.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) Evergreen.V387.Emoji.EmojiOrCustomEmoji Evergreen.V387.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Evergreen.V387.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) Evergreen.V387.Id.ThreadRouteWithMaybeMessage Evergreen.V387.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) Evergreen.V387.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V387.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V387.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
