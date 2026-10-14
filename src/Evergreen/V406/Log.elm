module Evergreen.V406.Log exposing (..)

import Effect.Http
import Evergreen.V406.Discord
import Evergreen.V406.EmailAddress
import Evergreen.V406.Emoji
import Evergreen.V406.Id
import Evergreen.V406.Postmark
import Evergreen.V406.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V406.Postmark.SendEmailError ()) Evergreen.V406.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V406.Postmark.SendEmailError Evergreen.V406.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | ChangedUsers (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V406.Postmark.SendEmailError Evergreen.V406.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji Evergreen.V406.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji Evergreen.V406.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji Evergreen.V406.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) Evergreen.V406.Emoji.EmojiOrCustomEmoji Evergreen.V406.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Evergreen.V406.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRouteWithMaybeMessage Evergreen.V406.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) Evergreen.V406.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V406.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V406.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId) Evergreen.V406.Slack.HttpError
    | FailedToSendSlackMessage Evergreen.V406.Id.SlackGuildOrDmId Evergreen.V406.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
