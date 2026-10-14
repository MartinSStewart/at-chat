module Evergreen.V407.Log exposing (..)

import Effect.Http
import Evergreen.V407.Discord
import Evergreen.V407.EmailAddress
import Evergreen.V407.Emoji
import Evergreen.V407.Id
import Evergreen.V407.Postmark
import Evergreen.V407.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V407.Postmark.SendEmailError ()) Evergreen.V407.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V407.Postmark.SendEmailError Evergreen.V407.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | ChangedUsers (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V407.Postmark.SendEmailError Evergreen.V407.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji Evergreen.V407.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji Evergreen.V407.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji Evergreen.V407.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) Evergreen.V407.Emoji.EmojiOrCustomEmoji Evergreen.V407.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Evergreen.V407.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRouteWithMaybeMessage Evergreen.V407.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) Evergreen.V407.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V407.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V407.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId) Evergreen.V407.Slack.HttpError
    | FailedToSendSlackMessage Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V407.Id.SlackGuildOrDmId Evergreen.V407.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
