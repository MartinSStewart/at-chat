module Evergreen.V419.Log exposing (..)

import Effect.Http
import Evergreen.V419.Discord
import Evergreen.V419.EmailAddress
import Evergreen.V419.Emoji
import Evergreen.V419.Id
import Evergreen.V419.Postmark
import Evergreen.V419.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V419.Postmark.SendEmailError ()) Evergreen.V419.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V419.Postmark.SendEmailError Evergreen.V419.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | ChangedUsers (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V419.Postmark.SendEmailError Evergreen.V419.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji Evergreen.V419.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji Evergreen.V419.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji Evergreen.V419.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) Evergreen.V419.Emoji.EmojiOrCustomEmoji Evergreen.V419.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Evergreen.V419.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRouteWithMaybeMessage Evergreen.V419.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) Evergreen.V419.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V419.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V419.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V419.Id.SlackGuildOrDmId Evergreen.V419.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
