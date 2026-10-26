module Evergreen.V414.Log exposing (..)

import Effect.Http
import Evergreen.V414.Discord
import Evergreen.V414.EmailAddress
import Evergreen.V414.Emoji
import Evergreen.V414.Id
import Evergreen.V414.Postmark
import Evergreen.V414.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V414.Postmark.SendEmailError ()) Evergreen.V414.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V414.Postmark.SendEmailError Evergreen.V414.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    | ChangedUsers (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V414.Postmark.SendEmailError Evergreen.V414.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) Evergreen.V414.Id.ThreadRouteWithMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) Evergreen.V414.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) Evergreen.V414.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) Evergreen.V414.Id.ThreadRouteWithMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) Evergreen.V414.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) Evergreen.V414.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) Evergreen.V414.Id.ThreadRouteWithMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) Evergreen.V414.Emoji.EmojiOrCustomEmoji Evergreen.V414.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) Evergreen.V414.Emoji.EmojiOrCustomEmoji Evergreen.V414.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) Evergreen.V414.Id.ThreadRouteWithMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) Evergreen.V414.Emoji.EmojiOrCustomEmoji Evergreen.V414.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) Evergreen.V414.Emoji.EmojiOrCustomEmoji Evergreen.V414.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) Evergreen.V414.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) Evergreen.V414.Id.ThreadRouteWithMaybeMessage Evergreen.V414.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) Evergreen.V414.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V414.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) Evergreen.V414.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) Evergreen.V414.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) Evergreen.V414.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V414.Id.Id Evergreen.V414.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V414.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) Evergreen.V414.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V414.Id.SlackGuildOrDmId Evergreen.V414.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V414.Id.SlackGuildOrDmId Evergreen.V414.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V414.Id.SlackGuildOrDmId Evergreen.V414.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V414.Id.SlackGuildOrDmId Evergreen.V414.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
