module Evergreen.V101.UserSession exposing (..)

import Effect.Http
import Evergreen.V101.Id
import Evergreen.V101.Message
import Evergreen.V101.SessionIdHash
import Evergreen.V101.UserAgent
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
    { userId : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRoute )
    , userAgent : Evergreen.V101.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V101.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.ThreadRoute )
    , userAgent : Evergreen.V101.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Evergreen.V101.Message.Message Evergreen.V101.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ThreadMessageId) (Evergreen.V101.Message.Message Evergreen.V101.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Evergreen.V101.Message.Message Evergreen.V101.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ThreadMessageId) (Evergreen.V101.Message.Message Evergreen.V101.Id.ThreadMessageId)))
    | StopViewingChannel
