module Evergreen.V163.UserSession exposing (..)

import Effect.Http
import Evergreen.V163.Discord
import Evergreen.V163.Id
import Evergreen.V163.Message
import Evergreen.V163.SessionIdHash
import Evergreen.V163.UserAgent
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
    { userId : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V163.Id.AnyGuildOrDmId, Evergreen.V163.Id.ThreadRoute )
    , userAgent : Evergreen.V163.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V163.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V163.Id.AnyGuildOrDmId, Evergreen.V163.Id.ThreadRoute )
    , userAgent : Evergreen.V163.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))))
    | ViewDmThread (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ThreadMessageId) (Evergreen.V163.Message.Message Evergreen.V163.Id.ThreadMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))))
    | ViewDiscordDm (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))))
    | ViewChannel (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))))
    | ViewChannelThread (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ThreadMessageId) (Evergreen.V163.Message.Message Evergreen.V163.Id.ThreadMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ThreadMessageId) (Evergreen.V163.Message.Message Evergreen.V163.Id.ThreadMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))))
    | StopViewingChannel
