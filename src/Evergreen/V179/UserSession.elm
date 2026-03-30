module Evergreen.V179.UserSession exposing (..)

import Effect.Http
import Evergreen.V179.Discord
import Evergreen.V179.Id
import Evergreen.V179.Message
import Evergreen.V179.SessionIdHash
import Evergreen.V179.UserAgent
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
    { userId : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute )
    , userAgent : Evergreen.V179.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V179.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute )
    , userAgent : Evergreen.V179.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))))
    | ViewDmThread (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))))
    | ViewDiscordDm (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))))
    | ViewChannel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))))
    | ViewChannelThread (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))))
    | StopViewingChannel
