module Evergreen.V217.UserSession exposing (..)

import Effect.Http
import Evergreen.V217.Discord
import Evergreen.V217.Id
import Evergreen.V217.Message
import Evergreen.V217.SessionIdHash
import Evergreen.V217.UserAgent
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
    { userId : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute )
    , userAgent : Evergreen.V217.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V217.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute )
    , userAgent : Evergreen.V217.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))))
    | ViewDmThread (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))))
    | ViewDiscordDm (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))))
    | ViewChannel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))))
    | ViewChannelThread (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))))
    | StopViewingChannel
