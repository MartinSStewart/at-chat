module Evergreen.V137.Log exposing (..)

import Effect.Http
import Evergreen.V137.Discord
import Evergreen.V137.Discord.Id
import Evergreen.V137.EmailAddress
import Evergreen.V137.Emoji
import Evergreen.V137.Id
import Evergreen.V137.Postmark


type Log
    = LoginEmail (Result Evergreen.V137.Postmark.SendEmailError ()) Evergreen.V137.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
    | ChangedUsers (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V137.Postmark.SendEmailError Evergreen.V137.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Emoji.Emoji Evergreen.V137.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Emoji.Emoji Evergreen.V137.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Emoji.Emoji Evergreen.V137.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Emoji.Emoji Evergreen.V137.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMaybeMessage Evergreen.V137.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) Evergreen.V137.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V137.Discord.HttpError
