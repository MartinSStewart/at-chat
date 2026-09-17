module Evergreen.V383.Log exposing (..)

import Effect.Http
import Evergreen.V383.Discord
import Evergreen.V383.EmailAddress
import Evergreen.V383.Emoji
import Evergreen.V383.Id
import Evergreen.V383.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V383.Postmark.SendEmailError ()) Evergreen.V383.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V383.Postmark.SendEmailError Evergreen.V383.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | ChangedUsers (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V383.Postmark.SendEmailError Evergreen.V383.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji Evergreen.V383.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji Evergreen.V383.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji Evergreen.V383.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) Evergreen.V383.Emoji.EmojiOrCustomEmoji Evergreen.V383.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Evergreen.V383.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) Evergreen.V383.Id.ThreadRouteWithMaybeMessage Evergreen.V383.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) Evergreen.V383.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V383.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V383.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
