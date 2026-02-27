module Evergreen.V124.UserSession exposing (..)

import Effect.Http
import Evergreen.V124.Discord.Id
import Evergreen.V124.Id
import Evergreen.V124.Message
import Evergreen.V124.SessionIdHash
import Evergreen.V124.UserAgent
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
    { userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    , userAgent : Evergreen.V124.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V124.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.ThreadRoute )
    , userAgent : Evergreen.V124.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))))
    | ViewDmThread (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))))
    | ViewDiscordDm (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))))
    | ViewChannelThread (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId) (Evergreen.V124.Message.Message Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))))
    | StopViewingChannel
