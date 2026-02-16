module Evergreen.V114.UserSession exposing (..)

import Effect.Http
import Evergreen.V114.Discord.Id
import Evergreen.V114.Id
import Evergreen.V114.Message
import Evergreen.V114.SessionIdHash
import Evergreen.V114.UserAgent
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
    { userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    , userAgent : Evergreen.V114.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V114.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    , userAgent : Evergreen.V114.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))))
    | ViewDmThread (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))))
    | ViewDiscordDm (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))))
    | ViewChannelThread (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))))
    | StopViewingChannel
