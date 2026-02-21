module Evergreen.V117.UserSession exposing (..)

import Effect.Http
import Evergreen.V117.Discord.Id
import Evergreen.V117.Id
import Evergreen.V117.Message
import Evergreen.V117.SessionIdHash
import Evergreen.V117.UserAgent
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
    { userId : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    , userAgent : Evergreen.V117.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V117.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    , userAgent : Evergreen.V117.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))))
    | ViewDmThread (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))))
    | ViewDiscordDm (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))))
    | ViewChannelThread (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))))
    | StopViewingChannel
