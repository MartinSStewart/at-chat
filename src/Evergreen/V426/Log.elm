module Evergreen.V426.Log exposing (..)

import Effect.Http
import Evergreen.V426.Discord
import Evergreen.V426.EmailAddress
import Evergreen.V426.Emoji
import Evergreen.V426.Id
import Evergreen.V426.Postmark
import Evergreen.V426.Slack
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V426.Postmark.SendEmailError ()) Evergreen.V426.EmailAddress.EmailAddress
    | FailedToSendNotificationEmail Evergreen.V426.Postmark.SendEmailError Evergreen.V426.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | ChangedUsers (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V426.Postmark.SendEmailError Evergreen.V426.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji Evergreen.V426.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji Evergreen.V426.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji Evergreen.V426.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) Evergreen.V426.Emoji.EmojiOrCustomEmoji Evergreen.V426.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Evergreen.V426.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRouteWithMaybeMessage Evergreen.V426.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V426.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.Discord.HttpError
    | FailedToReloadDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V426.Discord.HttpError
    | FailedToLoadDiscordGuildCustomEmojis (List.Nonempty.Nonempty ( Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToGenerateScheduledBackup Effect.Http.Error Int
    | FailedToRegenerateServerSecret Effect.Http.Error
    | FailedToDeleteOrphanedFiles Effect.Http.Error
    | FailedToLoadSlackConversations (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.Slack.HttpError
    | FailedToLoadSlackCustomEmojis (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) (List.Nonempty.Nonempty ( Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId, Effect.Http.Error )) Int
    | FailedToSendSlackMessage Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Slack.HttpError
    | FailedToChangeSlackReaction Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Slack.HttpError
    | FailedToDeleteSlackMessage Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Slack.HttpError
    | FailedToEditSlackMessage Evergreen.V426.Id.SlackGuildOrDmId Evergreen.V426.Slack.HttpError
    | ReceivedTypeThatIsAlwaysInvalid
    | DeletedLog
