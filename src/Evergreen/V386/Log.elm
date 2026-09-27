module Evergreen.V386.Log exposing (..)

import Effect.Http
import Evergreen.V386.Discord
import Evergreen.V386.EmailAddress
import Evergreen.V386.Emoji
import Evergreen.V386.Id
import Evergreen.V386.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V386.Postmark.SendEmailError ()) Evergreen.V386.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V386.Postmark.SendEmailError Evergreen.V386.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | ChangedUsers (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V386.Postmark.SendEmailError Evergreen.V386.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji Evergreen.V386.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji Evergreen.V386.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji Evergreen.V386.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) Evergreen.V386.Emoji.EmojiOrCustomEmoji Evergreen.V386.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Evergreen.V386.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) Evergreen.V386.Id.ThreadRouteWithMaybeMessage Evergreen.V386.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) Evergreen.V386.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V386.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V386.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
