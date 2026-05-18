module Evergreen.V238.UserSession exposing (..)

import Effect.Http
import Evergreen.V238.Discord
import Evergreen.V238.Id
import Evergreen.V238.Message
import Evergreen.V238.SessionIdHash
import Evergreen.V238.UserAgent
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
    { userId : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute )
    , userAgent : Evergreen.V238.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V238.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.ThreadRoute )
    , userAgent : Evergreen.V238.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))))
    | ViewDmThread (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))))
    | ViewDiscordDm (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))))
    | ViewChannel (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))))
    | ViewChannelThread (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId) (Evergreen.V238.Message.Message Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))))
    | StopViewingChannel
