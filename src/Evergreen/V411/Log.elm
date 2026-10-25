module Evergreen.V411.Log exposing (..)

import Effect.Http
import Evergreen.V411.Discord
import Evergreen.V411.EmailAddress
import Evergreen.V411.Emoji
import Evergreen.V411.Id
import Evergreen.V411.Postmark
import Evergreen.V411.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V411.Postmark.SendEmailError ()) Evergreen.V411.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V411.Postmark.SendEmailError Evergreen.V411.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
    | ChangedUsers (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V411.Postmark.SendEmailError Evergreen.V411.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId) Evergreen.V411.Id.ThreadRouteWithMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) Evergreen.V411.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) Evergreen.V411.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId) Evergreen.V411.Id.ThreadRouteWithMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) Evergreen.V411.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) Evergreen.V411.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId) Evergreen.V411.Id.ThreadRouteWithMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) Evergreen.V411.Emoji.EmojiOrCustomEmoji Evergreen.V411.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) Evergreen.V411.Emoji.EmojiOrCustomEmoji Evergreen.V411.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId) Evergreen.V411.Id.ThreadRouteWithMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) Evergreen.V411.Emoji.EmojiOrCustomEmoji Evergreen.V411.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) Evergreen.V411.Emoji.EmojiOrCustomEmoji Evergreen.V411.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) Evergreen.V411.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId) Evergreen.V411.Id.ThreadRouteWithMaybeMessage Evergreen.V411.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) Evergreen.V411.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V411.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) Evergreen.V411.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) Evergreen.V411.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) Evergreen.V411.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V411.Id.Id Evergreen.V411.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V411.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V411.Id.Id Evergreen.V411.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId) Evergreen.V411.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V411.Id.Id Evergreen.V411.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V411.Id.SlackGuildOrDmId Evergreen.V411.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V411.Id.SlackGuildOrDmId Evergreen.V411.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V411.Id.SlackGuildOrDmId Evergreen.V411.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V411.Id.SlackGuildOrDmId Evergreen.V411.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
