module Evergreen.V239.UserSession exposing (..)

import Effect.Http
import Evergreen.V239.Discord
import Evergreen.V239.Id
import Evergreen.V239.Message
import Evergreen.V239.SessionIdHash
import Evergreen.V239.UserAgent
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
    { userId : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute )
    , userAgent : Evergreen.V239.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V239.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute )
    , userAgent : Evergreen.V239.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))))
    | ViewDmThread (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))))
    | ViewDiscordDm (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))))
    | ViewChannel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))))
    | ViewChannelThread (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))))
    | StopViewingChannel
