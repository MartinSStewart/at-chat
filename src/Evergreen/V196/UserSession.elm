module Evergreen.V196.UserSession exposing (..)

import Effect.Http
import Evergreen.V196.Discord
import Evergreen.V196.Id
import Evergreen.V196.Message
import Evergreen.V196.SessionIdHash
import Evergreen.V196.UserAgent
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
    { userId : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V196.Id.AnyGuildOrDmId, Evergreen.V196.Id.ThreadRoute )
    , userAgent : Evergreen.V196.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V196.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V196.Id.AnyGuildOrDmId, Evergreen.V196.Id.ThreadRoute )
    , userAgent : Evergreen.V196.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))))
    | ViewDmThread (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ThreadMessageId) (Evergreen.V196.Message.Message Evergreen.V196.Id.ThreadMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))))
    | ViewDiscordDm (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))))
    | ViewChannel (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))))
    | ViewChannelThread (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ThreadMessageId) (Evergreen.V196.Message.Message Evergreen.V196.Id.ThreadMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ThreadMessageId) (Evergreen.V196.Message.Message Evergreen.V196.Id.ThreadMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))))
    | StopViewingChannel
