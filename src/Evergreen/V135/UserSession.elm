module Evergreen.V135.UserSession exposing (..)

import Effect.Http
import Evergreen.V135.Discord.Id
import Evergreen.V135.Id
import Evergreen.V135.Message
import Evergreen.V135.SessionIdHash
import Evergreen.V135.UserAgent
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
    { userId : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    , userAgent : Evergreen.V135.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V135.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    , userAgent : Evergreen.V135.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))))
    | ViewDmThread (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))))
    | ViewDiscordDm (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))))
    | ViewChannelThread (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))))
    | StopViewingChannel
