module Evergreen.V413.Log exposing (..)

import Effect.Http
import Evergreen.V413.Discord
import Evergreen.V413.EmailAddress
import Evergreen.V413.Emoji
import Evergreen.V413.Id
import Evergreen.V413.Postmark
import Evergreen.V413.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V413.Postmark.SendEmailError ()) Evergreen.V413.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V413.Postmark.SendEmailError Evergreen.V413.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | ChangedUsers (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V413.Postmark.SendEmailError Evergreen.V413.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji Evergreen.V413.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji Evergreen.V413.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji Evergreen.V413.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) Evergreen.V413.Emoji.EmojiOrCustomEmoji Evergreen.V413.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Evergreen.V413.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRouteWithMaybeMessage Evergreen.V413.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) Evergreen.V413.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V413.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) Evergreen.V413.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V413.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) Evergreen.V413.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V413.Id.SlackGuildOrDmId Evergreen.V413.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
