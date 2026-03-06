module Evergreen.V144.UserSession exposing (..)

import Effect.Http
import Evergreen.V144.Discord
import Evergreen.V144.Id
import Evergreen.V144.Message
import Evergreen.V144.SessionIdHash
import Evergreen.V144.UserAgent
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
    { userId : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    , userAgent : Evergreen.V144.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V144.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.ThreadRoute )
    , userAgent : Evergreen.V144.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))))
    | ViewDmThread (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))))
    | ViewDiscordDm (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))))
    | ViewChannel (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))))
    | ViewChannelThread (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId) (Evergreen.V144.Message.Message Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))))
    | StopViewingChannel
