module Evergreen.V248.UserSession exposing (..)

import Effect.Http
import Evergreen.V248.Discord
import Evergreen.V248.Id
import Evergreen.V248.Message
import Evergreen.V248.SessionIdHash
import Evergreen.V248.UserAgent
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
    { userId : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute )
    , userAgent : Evergreen.V248.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V248.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.ThreadRoute )
    , userAgent : Evergreen.V248.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))))
    | ViewDmThread (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))))
    | ViewDiscordDm (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))))
    | ViewChannel (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))))
    | ViewChannelThread (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId) (Evergreen.V248.Message.Message Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))))
    | StopViewingChannel
