module Evergreen.V94.UserSession exposing (..)

import Effect.Http
import Evergreen.V94.Id
import Evergreen.V94.Message
import Evergreen.V94.SessionIdHash
import Evergreen.V94.UserAgent
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
    { userId : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRoute )
    , userAgent : Evergreen.V94.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V94.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V94.Id.GuildOrDmIdNoThread, Evergreen.V94.Id.ThreadRoute )
    , userAgent : Evergreen.V94.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Evergreen.V94.Message.Message Evergreen.V94.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ThreadMessageId) (Evergreen.V94.Message.Message Evergreen.V94.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Evergreen.V94.Message.Message Evergreen.V94.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ThreadMessageId) (Evergreen.V94.Message.Message Evergreen.V94.Id.ThreadMessageId)))
    | StopViewingChannel
