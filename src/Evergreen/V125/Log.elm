module Evergreen.V125.Log exposing (..)

import Effect.Http
import Evergreen.V125.Discord
import Evergreen.V125.Discord.Id
import Evergreen.V125.EmailAddress
import Evergreen.V125.Emoji
import Evergreen.V125.Id
import Evergreen.V125.Postmark


type Log
    = LoginEmail (Result Evergreen.V125.Postmark.SendEmailError ()) Evergreen.V125.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    | ChangedUsers (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V125.Postmark.SendEmailError Evergreen.V125.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Emoji.Emoji Evergreen.V125.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Emoji.Emoji Evergreen.V125.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Emoji.Emoji Evergreen.V125.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Emoji.Emoji Evergreen.V125.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMaybeMessage Evergreen.V125.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) Evergreen.V125.Discord.HttpError
