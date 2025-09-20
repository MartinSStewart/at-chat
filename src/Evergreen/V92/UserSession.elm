module Evergreen.V92.UserSession exposing (..)

import Effect.Http
import Evergreen.V92.Id
import Evergreen.V92.Message
import Evergreen.V92.SessionIdHash
import Evergreen.V92.UserAgent
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
    { userId : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRoute )
    , userAgent : Evergreen.V92.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V92.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.ThreadRoute )
    , userAgent : Evergreen.V92.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Evergreen.V92.Message.Message Evergreen.V92.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ThreadMessageId) (Evergreen.V92.Message.Message Evergreen.V92.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Evergreen.V92.Message.Message Evergreen.V92.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ThreadMessageId) (Evergreen.V92.Message.Message Evergreen.V92.Id.ThreadMessageId)))
    | StopViewingChannel
