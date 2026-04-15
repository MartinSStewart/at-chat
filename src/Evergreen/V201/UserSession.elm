module Evergreen.V201.UserSession exposing (..)

import Effect.Http
import Evergreen.V201.Discord
import Evergreen.V201.Id
import Evergreen.V201.Message
import Evergreen.V201.SessionIdHash
import Evergreen.V201.UserAgent
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
    { userId : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute )
    , userAgent : Evergreen.V201.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V201.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute )
    , userAgent : Evergreen.V201.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))))
    | ViewDmThread (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))))
    | ViewDiscordDm (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))))
    | ViewChannel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))))
    | ViewChannelThread (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))))
    | StopViewingChannel
