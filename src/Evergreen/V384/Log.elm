module Evergreen.V384.Log exposing (..)

import Effect.Http
import Evergreen.V384.Discord
import Evergreen.V384.EmailAddress
import Evergreen.V384.Emoji
import Evergreen.V384.Id
import Evergreen.V384.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V384.Postmark.SendEmailError ()) Evergreen.V384.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V384.Postmark.SendEmailError Evergreen.V384.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | ChangedUsers (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V384.Postmark.SendEmailError Evergreen.V384.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji Evergreen.V384.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji Evergreen.V384.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji Evergreen.V384.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) Evergreen.V384.Emoji.EmojiOrCustomEmoji Evergreen.V384.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Evergreen.V384.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) Evergreen.V384.Id.ThreadRouteWithMaybeMessage Evergreen.V384.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) Evergreen.V384.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V384.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V384.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
