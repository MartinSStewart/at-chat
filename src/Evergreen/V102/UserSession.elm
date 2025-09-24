module Evergreen.V102.UserSession exposing (..)

import Effect.Http
import Evergreen.V102.Id
import Evergreen.V102.Message
import Evergreen.V102.SessionIdHash
import Evergreen.V102.UserAgent
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
    { userId : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRoute )
    , userAgent : Evergreen.V102.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V102.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.ThreadRoute )
    , userAgent : Evergreen.V102.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Evergreen.V102.Message.Message Evergreen.V102.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ThreadMessageId) (Evergreen.V102.Message.Message Evergreen.V102.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Evergreen.V102.Message.Message Evergreen.V102.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ThreadMessageId) (Evergreen.V102.Message.Message Evergreen.V102.Id.ThreadMessageId)))
    | StopViewingChannel
