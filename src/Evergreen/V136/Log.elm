module Evergreen.V136.Log exposing (..)

import Effect.Http
import Evergreen.V136.Discord
import Evergreen.V136.Discord.Id
import Evergreen.V136.EmailAddress
import Evergreen.V136.Emoji
import Evergreen.V136.Id
import Evergreen.V136.Postmark


type Log
    = LoginEmail (Result Evergreen.V136.Postmark.SendEmailError ()) Evergreen.V136.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
    | ChangedUsers (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V136.Postmark.SendEmailError Evergreen.V136.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Emoji.Emoji Evergreen.V136.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Emoji.Emoji Evergreen.V136.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Emoji.Emoji Evergreen.V136.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Emoji.Emoji Evergreen.V136.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMaybeMessage Evergreen.V136.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) Evergreen.V136.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V136.Discord.HttpError
