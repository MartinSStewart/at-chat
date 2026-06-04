module Evergreen.V275.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V275.Discord
import Evergreen.V275.Id
import Evergreen.V275.Message
import Evergreen.V275.Ports
import Evergreen.V275.SessionIdHash
import Evergreen.V275.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V275.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute )
    , userAgent : Evergreen.V275.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V275.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.ThreadRoute )
    , userAgent : Evergreen.V275.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))))
    | ViewDmThread (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))))
    | ViewDiscordDm (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))))
    | ViewChannel (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))))
    | ViewChannelThread (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId) (Evergreen.V275.Message.Message Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))))
    | StopViewingChannel
