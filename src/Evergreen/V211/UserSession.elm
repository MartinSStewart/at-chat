module Evergreen.V211.UserSession exposing (..)

import Effect.Http
import Evergreen.V211.Discord
import Evergreen.V211.Id
import Evergreen.V211.Message
import Evergreen.V211.SessionIdHash
import Evergreen.V211.UserAgent
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
    { userId : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V211.Id.AnyGuildOrDmId, Evergreen.V211.Id.ThreadRoute )
    , userAgent : Evergreen.V211.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V211.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V211.Id.AnyGuildOrDmId, Evergreen.V211.Id.ThreadRoute )
    , userAgent : Evergreen.V211.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))))
    | ViewDmThread (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ThreadMessageId) (Evergreen.V211.Message.Message Evergreen.V211.Id.ThreadMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))))
    | ViewDiscordDm (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))))
    | ViewChannel (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))))
    | ViewChannelThread (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ThreadMessageId) (Evergreen.V211.Message.Message Evergreen.V211.Id.ThreadMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ThreadMessageId) (Evergreen.V211.Message.Message Evergreen.V211.Id.ThreadMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))))
    | StopViewingChannel
