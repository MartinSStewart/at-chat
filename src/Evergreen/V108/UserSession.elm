module Evergreen.V108.UserSession exposing (..)

import Effect.Http
import Evergreen.V108.Id
import Evergreen.V108.Message
import Evergreen.V108.SessionIdHash
import Evergreen.V108.UserAgent
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
    { userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRoute )
    , userAgent : Evergreen.V108.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V108.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.ThreadRoute )
    , userAgent : Evergreen.V108.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Evergreen.V108.Message.Message Evergreen.V108.Id.ChannelMessageId)))
    | ViewDmThread (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ThreadMessageId) (Evergreen.V108.Message.Message Evergreen.V108.Id.ThreadMessageId)))
    | ViewChannel (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Evergreen.V108.Message.Message Evergreen.V108.Id.ChannelMessageId)))
    | ViewChannelThread (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ThreadMessageId) (Evergreen.V108.Message.Message Evergreen.V108.Id.ThreadMessageId)))
    | StopViewingChannel
