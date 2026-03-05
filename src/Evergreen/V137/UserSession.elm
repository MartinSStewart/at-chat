module Evergreen.V137.UserSession exposing (..)

import Effect.Http
import Evergreen.V137.Discord.Id
import Evergreen.V137.Id
import Evergreen.V137.Message
import Evergreen.V137.SessionIdHash
import Evergreen.V137.UserAgent
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
    { userId : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    , userAgent : Evergreen.V137.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V137.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    , userAgent : Evergreen.V137.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))))
    | ViewDmThread (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))))
    | ViewDiscordDm (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))))
    | ViewChannelThread (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))))
    | StopViewingChannel
