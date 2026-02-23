module Evergreen.V120.UserSession exposing (..)

import Effect.Http
import Evergreen.V120.Discord.Id
import Evergreen.V120.Id
import Evergreen.V120.Message
import Evergreen.V120.SessionIdHash
import Evergreen.V120.UserAgent
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
    { userId : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    , userAgent : Evergreen.V120.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V120.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.ThreadRoute )
    , userAgent : Evergreen.V120.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))))
    | ViewDmThread (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))))
    | ViewDiscordDm (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))))
    | ViewChannelThread (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId) (Evergreen.V120.Message.Message Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))))
    | StopViewingChannel
