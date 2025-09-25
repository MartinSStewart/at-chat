module Evergreen.V104.UserSession exposing (..)

import Effect.Http
import Evergreen.V104.Id
import Evergreen.V104.Message
import Evergreen.V104.SessionIdHash
import Evergreen.V104.UserAgent
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
    { userId : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRoute )
    , userAgent : Evergreen.V104.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V104.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V104.Id.GuildOrDmIdNoThread, Evergreen.V104.Id.ThreadRoute )
    , userAgent : Evergreen.V104.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Evergreen.V104.Message.Message Evergreen.V104.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ThreadMessageId) (Evergreen.V104.Message.Message Evergreen.V104.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Evergreen.V104.Message.Message Evergreen.V104.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ThreadMessageId) (Evergreen.V104.Message.Message Evergreen.V104.Id.ThreadMessageId)))
    | StopViewingChannel
