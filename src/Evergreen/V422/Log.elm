module Evergreen.V422.Log exposing (..)

import Effect.Http
import Evergreen.V422.Discord
import Evergreen.V422.EmailAddress
import Evergreen.V422.Emoji
import Evergreen.V422.Id
import Evergreen.V422.Postmark
import Evergreen.V422.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V422.Postmark.SendEmailError ()) Evergreen.V422.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V422.Postmark.SendEmailError Evergreen.V422.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | ChangedUsers (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V422.Postmark.SendEmailError Evergreen.V422.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji Evergreen.V422.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji Evergreen.V422.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji Evergreen.V422.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) Evergreen.V422.Emoji.EmojiOrCustomEmoji Evergreen.V422.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Evergreen.V422.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRouteWithMaybeMessage Evergreen.V422.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V422.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V422.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V422.Id.SlackGuildOrDmId Evergreen.V422.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
