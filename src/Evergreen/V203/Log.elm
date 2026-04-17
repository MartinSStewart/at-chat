module Evergreen.V203.Log exposing (..)

import Effect.Http
import Evergreen.V203.Discord
import Evergreen.V203.EmailAddress
import Evergreen.V203.Emoji
import Evergreen.V203.Id
import Evergreen.V203.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V203.Postmark.SendEmailError ()) Evergreen.V203.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
    | ChangedUsers (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V203.Postmark.SendEmailError Evergreen.V203.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Emoji.Emoji Evergreen.V203.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Emoji.Emoji Evergreen.V203.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Emoji.Emoji Evergreen.V203.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Emoji.Emoji Evergreen.V203.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMaybeMessage Evergreen.V203.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) Evergreen.V203.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V203.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V203.Discord.HttpError
    | FailedToGenerateScheduledBackup Effect.Http.Error
