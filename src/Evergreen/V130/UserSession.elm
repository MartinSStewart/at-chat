module Evergreen.V130.UserSession exposing (..)

import Effect.Http
import Evergreen.V130.Discord.Id
import Evergreen.V130.Id
import Evergreen.V130.Message
import Evergreen.V130.SessionIdHash
import Evergreen.V130.UserAgent
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
    { userId : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    , userAgent : Evergreen.V130.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V130.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.ThreadRoute )
    , userAgent : Evergreen.V130.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))))
    | ViewDmThread (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))))
    | ViewDiscordDm (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))))
    | ViewChannelThread (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId) (Evergreen.V130.Message.Message Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))))
    | StopViewingChannel
