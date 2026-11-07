module Evergreen.V421.Log exposing (..)

import Effect.Http
import Evergreen.V421.Discord
import Evergreen.V421.EmailAddress
import Evergreen.V421.Emoji
import Evergreen.V421.Id
import Evergreen.V421.Postmark
import Evergreen.V421.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V421.Postmark.SendEmailError ()) Evergreen.V421.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V421.Postmark.SendEmailError Evergreen.V421.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | ChangedUsers (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V421.Postmark.SendEmailError Evergreen.V421.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji Evergreen.V421.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji Evergreen.V421.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji Evergreen.V421.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) Evergreen.V421.Emoji.EmojiOrCustomEmoji Evergreen.V421.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Evergreen.V421.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRouteWithMaybeMessage Evergreen.V421.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) Evergreen.V421.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V421.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V421.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V421.Id.SlackGuildOrDmId Evergreen.V421.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
