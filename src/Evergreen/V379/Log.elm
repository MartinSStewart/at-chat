module Evergreen.V379.Log exposing (..)

import Effect.Http
import Evergreen.V379.Discord
import Evergreen.V379.EmailAddress
import Evergreen.V379.Emoji
import Evergreen.V379.Id
import Evergreen.V379.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V379.Postmark.SendEmailError ()) Evergreen.V379.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V379.Postmark.SendEmailError Evergreen.V379.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | ChangedUsers (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V379.Postmark.SendEmailError Evergreen.V379.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji Evergreen.V379.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji Evergreen.V379.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji Evergreen.V379.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) Evergreen.V379.Emoji.EmojiOrCustomEmoji Evergreen.V379.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Evergreen.V379.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) Evergreen.V379.Id.ThreadRouteWithMaybeMessage Evergreen.V379.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) Evergreen.V379.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V379.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V379.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error
    | FailedToRegenerateServerSecret Effect.Http.Error
    | ReceivedTypeThatIsAlwaysInvalid
