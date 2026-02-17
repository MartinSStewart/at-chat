module Evergreen.V115.UserSession exposing (..)

import Effect.Http
import Evergreen.V115.Discord.Id
import Evergreen.V115.Id
import Evergreen.V115.Message
import Evergreen.V115.SessionIdHash
import Evergreen.V115.UserAgent
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
    { userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    , userAgent : Evergreen.V115.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V115.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    , userAgent : Evergreen.V115.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))))
    | ViewDmThread (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))))
    | ViewDiscordDm (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))))
    | ViewChannelThread (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))))
    | StopViewingChannel
