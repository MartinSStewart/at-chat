module Evergreen.V90.UserSession exposing (..)

import Effect.Http
import Evergreen.V90.Id
import Evergreen.V90.Message
import Evergreen.V90.UserAgent
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
    { userId : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRoute )
    , userAgent : Evergreen.V90.UserAgent.UserAgent
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V90.Id.GuildOrDmIdNoThread, Evergreen.V90.Id.ThreadRoute )
    , userAgent : Evergreen.V90.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Evergreen.V90.Message.Message Evergreen.V90.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ThreadMessageId) (Evergreen.V90.Message.Message Evergreen.V90.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Evergreen.V90.Message.Message Evergreen.V90.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ThreadMessageId) (Evergreen.V90.Message.Message Evergreen.V90.Id.ThreadMessageId)))
    | StopViewingChannel
