module Evergreen.V409.Log exposing (..)

import Effect.Http
import Evergreen.V409.Discord
import Evergreen.V409.EmailAddress
import Evergreen.V409.Emoji
import Evergreen.V409.Id
import Evergreen.V409.Postmark
import Evergreen.V409.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V409.Postmark.SendEmailError ()) Evergreen.V409.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V409.Postmark.SendEmailError Evergreen.V409.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | ChangedUsers (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V409.Postmark.SendEmailError Evergreen.V409.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji Evergreen.V409.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji Evergreen.V409.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji Evergreen.V409.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) Evergreen.V409.Emoji.EmojiOrCustomEmoji Evergreen.V409.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Evergreen.V409.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRouteWithMaybeMessage Evergreen.V409.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) Evergreen.V409.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V409.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V409.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V409.Id.SlackGuildOrDmId Evergreen.V409.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
