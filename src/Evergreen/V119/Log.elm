module Evergreen.V119.Log exposing (..)

import Effect.Http
import Evergreen.V119.Discord
import Evergreen.V119.Discord.Id
import Evergreen.V119.EmailAddress
import Evergreen.V119.Emoji
import Evergreen.V119.Id
import Evergreen.V119.Postmark


type Log
    = LoginEmail (Result Evergreen.V119.Postmark.SendEmailError ()) Evergreen.V119.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
    | ChangedUsers (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V119.Postmark.SendEmailError Evergreen.V119.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Emoji.Emoji Evergreen.V119.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Emoji.Emoji Evergreen.V119.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) Evergreen.V119.Id.ThreadRouteWithMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Emoji.Emoji Evergreen.V119.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) Evergreen.V119.Emoji.Emoji Evergreen.V119.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.Discord.HttpError
