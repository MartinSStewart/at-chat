module Evergreen.V223.UserSession exposing (..)

import Effect.Http
import Evergreen.V223.Discord
import Evergreen.V223.Id
import Evergreen.V223.Message
import Evergreen.V223.SessionIdHash
import Evergreen.V223.UserAgent
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
    { userId : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V223.Id.AnyGuildOrDmId, Evergreen.V223.Id.ThreadRoute )
    , userAgent : Evergreen.V223.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V223.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V223.Id.AnyGuildOrDmId, Evergreen.V223.Id.ThreadRoute )
    , userAgent : Evergreen.V223.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))))
    | ViewDmThread (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ThreadMessageId) (Evergreen.V223.Message.Message Evergreen.V223.Id.ThreadMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))))
    | ViewDiscordDm (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))))
    | ViewChannel (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))))
    | ViewChannelThread (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ThreadMessageId) (Evergreen.V223.Message.Message Evergreen.V223.Id.ThreadMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ThreadMessageId) (Evergreen.V223.Message.Message Evergreen.V223.Id.ThreadMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))))
    | StopViewingChannel
