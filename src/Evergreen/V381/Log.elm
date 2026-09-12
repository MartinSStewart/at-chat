module Evergreen.V381.Log exposing (..)

import Effect.Http
import Evergreen.V381.Discord
import Evergreen.V381.EmailAddress
import Evergreen.V381.Emoji
import Evergreen.V381.Id
import Evergreen.V381.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V381.Postmark.SendEmailError ()) Evergreen.V381.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V381.Postmark.SendEmailError Evergreen.V381.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | ChangedUsers (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V381.Postmark.SendEmailError Evergreen.V381.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji Evergreen.V381.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji Evergreen.V381.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji Evergreen.V381.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) Evergreen.V381.Emoji.EmojiOrCustomEmoji Evergreen.V381.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Evergreen.V381.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) Evergreen.V381.Id.ThreadRouteWithMaybeMessage Evergreen.V381.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) Evergreen.V381.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V381.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V381.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
