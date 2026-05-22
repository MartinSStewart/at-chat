module Evergreen.V243.UserSession exposing (..)

import Effect.Http
import Evergreen.V243.Discord
import Evergreen.V243.Id
import Evergreen.V243.Message
import Evergreen.V243.SessionIdHash
import Evergreen.V243.UserAgent
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
    { userId : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute )
    , userAgent : Evergreen.V243.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V243.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.ThreadRoute )
    , userAgent : Evergreen.V243.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))))
    | ViewDmThread (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))))
    | ViewDiscordDm (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))))
    | ViewChannel (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))))
    | ViewChannelThread (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId) (Evergreen.V243.Message.Message Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))))
    | StopViewingChannel
