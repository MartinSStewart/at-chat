module Evergreen.V197.UserSession exposing (..)

import Effect.Http
import Evergreen.V197.Discord
import Evergreen.V197.Id
import Evergreen.V197.Message
import Evergreen.V197.SessionIdHash
import Evergreen.V197.UserAgent
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
    { userId : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute )
    , userAgent : Evergreen.V197.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V197.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.ThreadRoute )
    , userAgent : Evergreen.V197.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))))
    | ViewDmThread (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))))
    | ViewDiscordDm (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))))
    | ViewChannel (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))))
    | ViewChannelThread (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId) (Evergreen.V197.Message.Message Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))))
    | StopViewingChannel
