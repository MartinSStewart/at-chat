module Evergreen.V116.UserSession exposing (..)

import Effect.Http
import Evergreen.V116.Discord.Id
import Evergreen.V116.Id
import Evergreen.V116.Message
import Evergreen.V116.SessionIdHash
import Evergreen.V116.UserAgent
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
    { userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    , userAgent : Evergreen.V116.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V116.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    , userAgent : Evergreen.V116.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))))
    | ViewDmThread (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))))
    | ViewDiscordDm (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))))
    | ViewChannelThread (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))))
    | StopViewingChannel
