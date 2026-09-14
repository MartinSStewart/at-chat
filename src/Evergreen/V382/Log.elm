module Evergreen.V382.Log exposing (..)

import Effect.Http
import Evergreen.V382.Discord
import Evergreen.V382.EmailAddress
import Evergreen.V382.Emoji
import Evergreen.V382.Id
import Evergreen.V382.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V382.Postmark.SendEmailError ()) Evergreen.V382.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V382.Postmark.SendEmailError Evergreen.V382.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | ChangedUsers (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V382.Postmark.SendEmailError Evergreen.V382.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji Evergreen.V382.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji Evergreen.V382.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji Evergreen.V382.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) Evergreen.V382.Emoji.EmojiOrCustomEmoji Evergreen.V382.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Evergreen.V382.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) Evergreen.V382.Id.ThreadRouteWithMaybeMessage Evergreen.V382.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) Evergreen.V382.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V382.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V382.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
