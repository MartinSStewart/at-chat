module Evergreen.V266.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V266.Discord
import Evergreen.V266.Id
import Evergreen.V266.Message
import Evergreen.V266.SessionIdHash
import Evergreen.V266.UserAgent
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
    | Subscribed SubscribeData Effect.Time.Posix
    | SubscriptionError Effect.Http.Error


type alias UserSession =
    { userId : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute )
    , userAgent : Evergreen.V266.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V266.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.ThreadRoute )
    , userAgent : Evergreen.V266.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))))
    | ViewDmThread (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))))
    | ViewDiscordDm (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))))
    | ViewChannel (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))))
    | ViewChannelThread (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId) (Evergreen.V266.Message.Message Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))))
    | StopViewingChannel
