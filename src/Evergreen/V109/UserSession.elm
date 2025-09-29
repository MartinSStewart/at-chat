module Evergreen.V109.UserSession exposing (..)

import Effect.Http
import Evergreen.V109.Id
import Evergreen.V109.Message
import Evergreen.V109.SessionIdHash
import Evergreen.V109.UserAgent
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
    { userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRoute )
    , userAgent : Evergreen.V109.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V109.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.ThreadRoute )
    , userAgent : Evergreen.V109.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Evergreen.V109.Message.Message Evergreen.V109.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ThreadMessageId) (Evergreen.V109.Message.Message Evergreen.V109.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Evergreen.V109.Message.Message Evergreen.V109.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ThreadMessageId) (Evergreen.V109.Message.Message Evergreen.V109.Id.ThreadMessageId)))
    | StopViewingChannel
