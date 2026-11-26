module Evergreen.V425.Log exposing (..)

import Effect.Http
import Evergreen.V425.Discord
import Evergreen.V425.EmailAddress
import Evergreen.V425.Emoji
import Evergreen.V425.Id
import Evergreen.V425.Postmark
import Evergreen.V425.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V425.Postmark.SendEmailError ()) Evergreen.V425.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V425.Postmark.SendEmailError Evergreen.V425.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | ChangedUsers (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V425.Postmark.SendEmailError Evergreen.V425.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji Evergreen.V425.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji Evergreen.V425.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji Evergreen.V425.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) Evergreen.V425.Emoji.EmojiOrCustomEmoji Evergreen.V425.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Evergreen.V425.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRouteWithMaybeMessage Evergreen.V425.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V425.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V425.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V425.Id.SlackGuildOrDmId Evergreen.V425.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
