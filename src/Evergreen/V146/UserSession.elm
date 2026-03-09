module Evergreen.V146.UserSession exposing (..)

import Effect.Http
import Evergreen.V146.Discord
import Evergreen.V146.Id
import Evergreen.V146.Message
import Evergreen.V146.SessionIdHash
import Evergreen.V146.UserAgent
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
    { userId : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    , userAgent : Evergreen.V146.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V146.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.ThreadRoute )
    , userAgent : Evergreen.V146.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))))
    | ViewDmThread (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))))
    | ViewDiscordDm (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))))
    | ViewChannel (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))))
    | ViewChannelThread (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId) (Evergreen.V146.Message.Message Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))))
    | StopViewingChannel
