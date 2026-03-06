module Evergreen.V138.UserSession exposing (..)

import Effect.Http
import Evergreen.V138.Discord.Id
import Evergreen.V138.Id
import Evergreen.V138.Message
import Evergreen.V138.SessionIdHash
import Evergreen.V138.UserAgent
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
    { userId : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    , userAgent : Evergreen.V138.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V138.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    , userAgent : Evergreen.V138.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))))
    | ViewDmThread (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))))
    | ViewDiscordDm (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))))
    | ViewChannelThread (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))))
    | StopViewingChannel
