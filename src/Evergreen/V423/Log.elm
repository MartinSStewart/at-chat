module Evergreen.V423.Log exposing (..)

import Effect.Http
import Evergreen.V423.Discord
import Evergreen.V423.EmailAddress
import Evergreen.V423.Emoji
import Evergreen.V423.Id
import Evergreen.V423.Postmark
import Evergreen.V423.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V423.Postmark.SendEmailError ()) Evergreen.V423.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V423.Postmark.SendEmailError Evergreen.V423.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | ChangedUsers (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V423.Postmark.SendEmailError Evergreen.V423.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji Evergreen.V423.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji Evergreen.V423.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji Evergreen.V423.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) Evergreen.V423.Emoji.EmojiOrCustomEmoji Evergreen.V423.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Evergreen.V423.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRouteWithMaybeMessage Evergreen.V423.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Evergreen.V423.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V423.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V423.Id.Id Evergreen.V423.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V423.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V423.Id.Id Evergreen.V423.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V423.Id.SlackGuildOrDmId Evergreen.V423.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
