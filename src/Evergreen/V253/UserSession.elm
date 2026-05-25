module Evergreen.V253.UserSession exposing (..)

import Effect.Http
import Evergreen.V253.Discord
import Evergreen.V253.Id
import Evergreen.V253.Message
import Evergreen.V253.SessionIdHash
import Evergreen.V253.UserAgent
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
    { userId : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute )
    , userAgent : Evergreen.V253.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V253.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.ThreadRoute )
    , userAgent : Evergreen.V253.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))))
    | ViewDmThread (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))))
    | ViewDiscordDm (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))))
    | ViewChannel (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))))
    | ViewChannelThread (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId) (Evergreen.V253.Message.Message Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))))
    | StopViewingChannel
