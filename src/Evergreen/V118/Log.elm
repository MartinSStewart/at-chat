module Evergreen.V118.Log exposing (..)

import Effect.Http
import Evergreen.V118.Discord
import Evergreen.V118.Discord.Id
import Evergreen.V118.EmailAddress
import Evergreen.V118.Emoji
import Evergreen.V118.Id
import Evergreen.V118.Postmark


type Log
    = LoginEmail (Result Evergreen.V118.Postmark.SendEmailError ()) Evergreen.V118.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
    | ChangedUsers (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V118.Postmark.SendEmailError Evergreen.V118.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Emoji.Emoji Evergreen.V118.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Emoji.Emoji Evergreen.V118.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) Evergreen.V118.Id.ThreadRouteWithMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Emoji.Emoji Evergreen.V118.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) Evergreen.V118.Emoji.Emoji Evergreen.V118.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Evergreen.V118.Discord.HttpError
