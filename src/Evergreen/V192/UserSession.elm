module Evergreen.V192.UserSession exposing (..)

import Effect.Http
import Evergreen.V192.Discord
import Evergreen.V192.Id
import Evergreen.V192.Message
import Evergreen.V192.SessionIdHash
import Evergreen.V192.UserAgent
import SeqDict
import Url


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type alias SubscribeData =
    { endpoint : Url.Url
    , auth : String
    , p256dh : String
    }


type PushSubscription
    = NotSubscribed
    | Subscribed SubscribeData
    | SubscriptionError Effect.Http.Error


type alias UserSession =
    { userId : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute )
    , userAgent : Evergreen.V192.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V192.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.ThreadRoute )
    , userAgent : Evergreen.V192.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))))
    | ViewDmThread (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))))
    | ViewDiscordDm (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))))
    | ViewChannel (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))))
    | ViewChannelThread (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId) (Evergreen.V192.Message.Message Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))))
    | StopViewingChannel
