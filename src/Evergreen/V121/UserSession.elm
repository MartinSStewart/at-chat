module Evergreen.V121.UserSession exposing (..)

import Effect.Http
import Evergreen.V121.Discord.Id
import Evergreen.V121.Id
import Evergreen.V121.Message
import Evergreen.V121.SessionIdHash
import Evergreen.V121.UserAgent
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
    { userId : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V121.Id.AnyGuildOrDmId, Evergreen.V121.Id.ThreadRoute )
    , userAgent : Evergreen.V121.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V121.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V121.Id.AnyGuildOrDmId, Evergreen.V121.Id.ThreadRoute )
    , userAgent : Evergreen.V121.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Evergreen.V121.Message.Message Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))))
    | ViewDmThread (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ThreadMessageId) (Evergreen.V121.Message.Message Evergreen.V121.Id.ThreadMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))))
    | ViewDiscordDm (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Evergreen.V121.Message.Message Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V121.Id.Id Evergreen.V121.Id.GuildId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Evergreen.V121.Message.Message Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))))
    | ViewChannelThread (Evergreen.V121.Id.Id Evergreen.V121.Id.GuildId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ThreadMessageId) (Evergreen.V121.Message.Message Evergreen.V121.Id.ThreadMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Evergreen.V121.Message.Message Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ThreadMessageId) (Evergreen.V121.Message.Message Evergreen.V121.Id.ThreadMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))))
    | StopViewingChannel
