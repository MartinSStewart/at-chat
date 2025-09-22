module Evergreen.V93.UserSession exposing (..)

import Effect.Http
import Evergreen.V93.Id
import Evergreen.V93.Message
import Evergreen.V93.SessionIdHash
import Evergreen.V93.UserAgent
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
    { userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRoute )
    , userAgent : Evergreen.V93.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V93.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V93.Id.GuildOrDmIdNoThread, Evergreen.V93.Id.ThreadRoute )
    , userAgent : Evergreen.V93.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Evergreen.V93.Message.Message Evergreen.V93.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ThreadMessageId) (Evergreen.V93.Message.Message Evergreen.V93.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Evergreen.V93.Message.Message Evergreen.V93.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ThreadMessageId) (Evergreen.V93.Message.Message Evergreen.V93.Id.ThreadMessageId)))
    | StopViewingChannel
