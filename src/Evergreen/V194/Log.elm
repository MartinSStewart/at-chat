module Evergreen.V194.Log exposing (..)

import Effect.Http
import Evergreen.V194.Discord
import Evergreen.V194.EmailAddress
import Evergreen.V194.Emoji
import Evergreen.V194.Id
import Evergreen.V194.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V194.Postmark.SendEmailError ()) Evergreen.V194.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
    | ChangedUsers (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V194.Postmark.SendEmailError Evergreen.V194.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Emoji.Emoji Evergreen.V194.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Emoji.Emoji Evergreen.V194.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Emoji.Emoji Evergreen.V194.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Emoji.Emoji Evergreen.V194.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMaybeMessage Evergreen.V194.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) Evergreen.V194.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V194.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V194.Discord.HttpError
