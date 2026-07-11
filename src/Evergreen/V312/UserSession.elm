module Evergreen.V312.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V312.Discord
import Evergreen.V312.FileStatus
import Evergreen.V312.Id
import Evergreen.V312.Message
import Evergreen.V312.PersonName
import Evergreen.V312.Ports
import Evergreen.V312.SessionIdHash
import Evergreen.V312.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V312.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V312.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V312.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V312.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V312.PersonName.PersonName
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute ))
    , userAgent : Evergreen.V312.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V312.Id.Id messageId) (Evergreen.V312.Message.Message messageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))))
    | ViewDmThread (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))))
    | ViewDiscordDm (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))))
    | ViewChannel (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))))
    | ViewChannelThread (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId) (Evergreen.V312.Message.Message Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V312.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V312.Id.ThreadMessageId))
    | StopViewingChannel
