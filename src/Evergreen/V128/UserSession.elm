module Evergreen.V128.UserSession exposing (..)

import Effect.Http
import Evergreen.V128.Discord.Id
import Evergreen.V128.Id
import Evergreen.V128.Message
import Evergreen.V128.SessionIdHash
import Evergreen.V128.UserAgent
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
    { userId : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    , userAgent : Evergreen.V128.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V128.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.ThreadRoute )
    , userAgent : Evergreen.V128.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))))
    | ViewDmThread (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))))
    | ViewDiscordDm (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))))
    | ViewChannelThread (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId) (Evergreen.V128.Message.Message Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))))
    | StopViewingChannel
