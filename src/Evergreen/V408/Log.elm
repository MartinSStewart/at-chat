module Evergreen.V408.Log exposing (..)

import Effect.Http
import Evergreen.V408.Discord
import Evergreen.V408.EmailAddress
import Evergreen.V408.Emoji
import Evergreen.V408.Id
import Evergreen.V408.Postmark
import Evergreen.V408.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V408.Postmark.SendEmailError ()) Evergreen.V408.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V408.Postmark.SendEmailError Evergreen.V408.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | ChangedUsers (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V408.Postmark.SendEmailError Evergreen.V408.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji Evergreen.V408.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji Evergreen.V408.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji Evergreen.V408.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) Evergreen.V408.Emoji.EmojiOrCustomEmoji Evergreen.V408.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Evergreen.V408.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRouteWithMaybeMessage Evergreen.V408.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) Evergreen.V408.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V408.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V408.Id.Id Evergreen.V408.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V408.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V408.Id.Id Evergreen.V408.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V408.Id.SlackGuildOrDmId Evergreen.V408.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
