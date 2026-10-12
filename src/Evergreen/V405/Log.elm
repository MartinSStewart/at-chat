module Evergreen.V405.Log exposing (..)

import Effect.Http
import Evergreen.V405.Discord
import Evergreen.V405.EmailAddress
import Evergreen.V405.Emoji
import Evergreen.V405.Id
import Evergreen.V405.Postmark
import Evergreen.V405.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V405.Postmark.SendEmailError ()) Evergreen.V405.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V405.Postmark.SendEmailError Evergreen.V405.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | ChangedUsers (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V405.Postmark.SendEmailError Evergreen.V405.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji Evergreen.V405.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji Evergreen.V405.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji Evergreen.V405.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) Evergreen.V405.Emoji.EmojiOrCustomEmoji Evergreen.V405.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Evergreen.V405.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRouteWithMaybeMessage Evergreen.V405.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) Evergreen.V405.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V405.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V405.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId) Evergreen.V405.Slack.HttpError
    | FailedToSendSlackMessage Evergreen.V405.Id.SlackGuildOrDmId Evergreen.V405.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
