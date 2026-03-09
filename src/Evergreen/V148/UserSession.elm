module Evergreen.V148.UserSession exposing (..)

import Effect.Http
import Evergreen.V148.Discord
import Evergreen.V148.Id
import Evergreen.V148.Message
import Evergreen.V148.SessionIdHash
import Evergreen.V148.UserAgent
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
    { userId : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    , userAgent : Evergreen.V148.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V148.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.ThreadRoute )
    , userAgent : Evergreen.V148.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))))
    | ViewDmThread (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))))
    | ViewDiscordDm (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))))
    | ViewChannel (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))))
    | ViewChannelThread (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId) (Evergreen.V148.Message.Message Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))))
    | StopViewingChannel
