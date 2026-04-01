module Evergreen.V183.UserSession exposing (..)

import Effect.Http
import Evergreen.V183.Discord
import Evergreen.V183.Id
import Evergreen.V183.Message
import Evergreen.V183.SessionIdHash
import Evergreen.V183.UserAgent
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
    { userId : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute )
    , userAgent : Evergreen.V183.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V183.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.ThreadRoute )
    , userAgent : Evergreen.V183.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))))
    | ViewDmThread (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))))
    | ViewDiscordDm (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))))
    | ViewChannel (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))))
    | ViewChannelThread (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId) (Evergreen.V183.Message.Message Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))))
    | StopViewingChannel
