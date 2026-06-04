module Evergreen.V273.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V273.Discord
import Evergreen.V273.Id
import Evergreen.V273.Message
import Evergreen.V273.Ports
import Evergreen.V273.SessionIdHash
import Evergreen.V273.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V273.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute )
    , userAgent : Evergreen.V273.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V273.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.ThreadRoute )
    , userAgent : Evergreen.V273.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))))
    | ViewDmThread (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))))
    | ViewDiscordDm (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))))
    | ViewChannel (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))))
    | ViewChannelThread (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId) (Evergreen.V273.Message.Message Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))))
    | StopViewingChannel
