module Evergreen.V417.Log exposing (..)

import Effect.Http
import Evergreen.V417.Discord
import Evergreen.V417.EmailAddress
import Evergreen.V417.Emoji
import Evergreen.V417.Id
import Evergreen.V417.Postmark
import Evergreen.V417.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V417.Postmark.SendEmailError ()) Evergreen.V417.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V417.Postmark.SendEmailError Evergreen.V417.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | ChangedUsers (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V417.Postmark.SendEmailError Evergreen.V417.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji Evergreen.V417.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji Evergreen.V417.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji Evergreen.V417.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) Evergreen.V417.Emoji.EmojiOrCustomEmoji Evergreen.V417.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Evergreen.V417.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRouteWithMaybeMessage Evergreen.V417.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) Evergreen.V417.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V417.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V417.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V417.Id.SlackGuildOrDmId Evergreen.V417.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
