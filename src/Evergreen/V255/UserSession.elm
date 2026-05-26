module Evergreen.V255.UserSession exposing (..)

import Effect.Http
import Evergreen.V255.Discord
import Evergreen.V255.Id
import Evergreen.V255.Message
import Evergreen.V255.SessionIdHash
import Evergreen.V255.UserAgent
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
    { userId : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute )
    , userAgent : Evergreen.V255.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V255.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.ThreadRoute )
    , userAgent : Evergreen.V255.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))))
    | ViewDmThread (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))))
    | ViewDiscordDm (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))))
    | ViewChannel (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))))
    | ViewChannelThread (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId) (Evergreen.V255.Message.Message Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))))
    | StopViewingChannel
