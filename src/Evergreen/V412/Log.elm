module Evergreen.V412.Log exposing (..)

import Effect.Http
import Evergreen.V412.Discord
import Evergreen.V412.EmailAddress
import Evergreen.V412.Emoji
import Evergreen.V412.Id
import Evergreen.V412.Postmark
import Evergreen.V412.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V412.Postmark.SendEmailError ()) Evergreen.V412.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V412.Postmark.SendEmailError Evergreen.V412.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | ChangedUsers (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V412.Postmark.SendEmailError Evergreen.V412.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji Evergreen.V412.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji Evergreen.V412.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji Evergreen.V412.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) Evergreen.V412.Emoji.EmojiOrCustomEmoji Evergreen.V412.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Evergreen.V412.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) Evergreen.V412.Id.ThreadRouteWithMaybeMessage Evergreen.V412.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) Evergreen.V412.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V412.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V412.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V412.Id.SlackGuildOrDmId Evergreen.V412.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
