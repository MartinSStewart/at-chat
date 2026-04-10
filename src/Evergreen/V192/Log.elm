module Evergreen.V192.Log exposing (..)

import Effect.Http
import Evergreen.V192.Discord
import Evergreen.V192.EmailAddress
import Evergreen.V192.Emoji
import Evergreen.V192.Id
import Evergreen.V192.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V192.Postmark.SendEmailError ()) Evergreen.V192.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
    | ChangedUsers (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V192.Postmark.SendEmailError Evergreen.V192.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Emoji.Emoji Evergreen.V192.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Emoji.Emoji Evergreen.V192.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Emoji.Emoji Evergreen.V192.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) Evergreen.V192.Emoji.Emoji Evergreen.V192.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) Evergreen.V192.Id.ThreadRouteWithMaybeMessage Evergreen.V192.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) Evergreen.V192.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V192.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) Evergreen.V192.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V192.Discord.HttpError
