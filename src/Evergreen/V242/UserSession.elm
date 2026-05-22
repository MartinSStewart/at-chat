module Evergreen.V242.UserSession exposing (..)

import Effect.Http
import Evergreen.V242.Discord
import Evergreen.V242.Id
import Evergreen.V242.Message
import Evergreen.V242.SessionIdHash
import Evergreen.V242.UserAgent
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
    { userId : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute )
    , userAgent : Evergreen.V242.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V242.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.ThreadRoute )
    , userAgent : Evergreen.V242.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))))
    | ViewDmThread (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))))
    | ViewDiscordDm (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))))
    | ViewChannel (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))))
    | ViewChannelThread (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId) (Evergreen.V242.Message.Message Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))))
    | StopViewingChannel
