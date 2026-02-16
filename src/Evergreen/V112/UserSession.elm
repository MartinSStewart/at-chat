module Evergreen.V112.UserSession exposing (..)

import Effect.Http
import Evergreen.V112.Discord.Id
import Evergreen.V112.Id
import Evergreen.V112.Message
import Evergreen.V112.SessionIdHash
import Evergreen.V112.UserAgent
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
    { userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    , userAgent : Evergreen.V112.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V112.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    , userAgent : Evergreen.V112.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))))
    | ViewDmThread (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))))
    | ViewDiscordDm (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))))
    | ViewChannelThread (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))))
    | StopViewingChannel
