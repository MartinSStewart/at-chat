module Evergreen.V122.UserSession exposing (..)

import Effect.Http
import Evergreen.V122.Discord.Id
import Evergreen.V122.Id
import Evergreen.V122.Message
import Evergreen.V122.SessionIdHash
import Evergreen.V122.UserAgent
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
    { userId : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    , userAgent : Evergreen.V122.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V122.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.ThreadRoute )
    , userAgent : Evergreen.V122.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))))
    | ViewDmThread (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))))
    | ViewDiscordDm (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))))
    | ViewChannelThread (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId) (Evergreen.V122.Message.Message Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))))
    | StopViewingChannel
