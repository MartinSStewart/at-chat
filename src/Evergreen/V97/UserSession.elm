module Evergreen.V97.UserSession exposing (..)

import Effect.Http
import Evergreen.V97.Id
import Evergreen.V97.Message
import Evergreen.V97.SessionIdHash
import Evergreen.V97.UserAgent
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
    { userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRoute )
    , userAgent : Evergreen.V97.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V97.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.ThreadRoute )
    , userAgent : Evergreen.V97.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Evergreen.V97.Message.Message Evergreen.V97.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ThreadMessageId) (Evergreen.V97.Message.Message Evergreen.V97.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Evergreen.V97.Message.Message Evergreen.V97.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ThreadMessageId) (Evergreen.V97.Message.Message Evergreen.V97.Id.ThreadMessageId)))
    | StopViewingChannel
