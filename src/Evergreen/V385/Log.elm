module Evergreen.V385.Log exposing (..)

import Effect.Http
import Evergreen.V385.Discord
import Evergreen.V385.EmailAddress
import Evergreen.V385.Emoji
import Evergreen.V385.Id
import Evergreen.V385.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V385.Postmark.SendEmailError ()) Evergreen.V385.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V385.Postmark.SendEmailError Evergreen.V385.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | ChangedUsers (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V385.Postmark.SendEmailError Evergreen.V385.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji Evergreen.V385.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji Evergreen.V385.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji Evergreen.V385.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) Evergreen.V385.Emoji.EmojiOrCustomEmoji Evergreen.V385.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Evergreen.V385.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) Evergreen.V385.Id.ThreadRouteWithMaybeMessage Evergreen.V385.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) Evergreen.V385.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V385.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V385.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
