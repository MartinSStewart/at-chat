module Evergreen.V193.Log exposing (..)

import Effect.Http
import Evergreen.V193.Discord
import Evergreen.V193.EmailAddress
import Evergreen.V193.Emoji
import Evergreen.V193.Id
import Evergreen.V193.Postmark
import List.Nonempty


type Log
    = LoginEmail (Result Evergreen.V193.Postmark.SendEmailError ()) Evergreen.V193.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
    | ChangedUsers (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V193.Postmark.SendEmailError Evergreen.V193.EmailAddress.EmailAddress
    | PushNotificationError (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Effect.Http.Error
    | FailedToDeleteDiscordGuildMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Discord.HttpError
    | FailedToDeleteDiscordDmMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Discord.HttpError
    | FailedToEditDiscordGuildMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Discord.HttpError
    | FailedToEditDiscordDmMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Discord.HttpError
    | FailedToAddReactionToDiscordGuildMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Emoji.Emoji Evergreen.V193.Discord.HttpError
    | FailedToAddReactionToDiscordDmMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Emoji.Emoji Evergreen.V193.Discord.HttpError
    | FailedToRemoveReactionToDiscordGuildMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Emoji.Emoji Evergreen.V193.Discord.HttpError
    | FailedToRemoveReactionToDiscordDmMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Emoji.Emoji Evergreen.V193.Discord.HttpError
    | FailedToLoadDiscordUserData (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.Discord.HttpError
    | FailedToSendDiscordGuildMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMaybeMessage Evergreen.V193.Discord.HttpError
    | FailedToSendDiscordDmMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) Evergreen.V193.Discord.HttpError
    | FailedToGetDiscordUserAvatars Evergreen.V193.Discord.HttpError
    | FailedToParseDiscordWebsocket (Maybe String) String
    | FailedToGetDataForJoinedOrCreatedDiscordGuild (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.Discord.HttpError
    | JoinedDiscordThreadFailed (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.Discord.HttpError
    | EmptyDiscordMessage String
    | FailedToLoadDiscordGuildStickers (List.Nonempty.Nonempty ( Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId, Effect.Http.Error )) Int
    | FailedToLoadDiscordStandardStickerPacks Evergreen.V193.Discord.HttpError
