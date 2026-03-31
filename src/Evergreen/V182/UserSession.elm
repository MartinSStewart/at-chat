module Evergreen.V182.UserSession exposing (..)

import Effect.Http
import Evergreen.V182.Discord
import Evergreen.V182.Id
import Evergreen.V182.Message
import Evergreen.V182.SessionIdHash
import Evergreen.V182.UserAgent
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
    { userId : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V182.Id.AnyGuildOrDmId, Evergreen.V182.Id.ThreadRoute )
    , userAgent : Evergreen.V182.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V182.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V182.Id.AnyGuildOrDmId, Evergreen.V182.Id.ThreadRoute )
    , userAgent : Evergreen.V182.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))))
    | ViewDmThread (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ThreadMessageId) (Evergreen.V182.Message.Message Evergreen.V182.Id.ThreadMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))))
    | ViewDiscordDm (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))))
    | ViewChannel (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))))
    | ViewChannelThread (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ThreadMessageId) (Evergreen.V182.Message.Message Evergreen.V182.Id.ThreadMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ThreadMessageId) (Evergreen.V182.Message.Message Evergreen.V182.Id.ThreadMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))))
    | StopViewingChannel
