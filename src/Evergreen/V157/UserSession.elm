module Evergreen.V157.UserSession exposing (..)

import Effect.Http
import Evergreen.V157.Discord
import Evergreen.V157.Id
import Evergreen.V157.Message
import Evergreen.V157.SessionIdHash
import Evergreen.V157.UserAgent
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
    { userId : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    , userAgent : Evergreen.V157.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V157.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.ThreadRoute )
    , userAgent : Evergreen.V157.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))))
    | ViewDmThread (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))))
    | ViewDiscordDm (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))))
    | ViewChannel (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))))
    | ViewChannelThread (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId) (Evergreen.V157.Message.Message Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))))
    | StopViewingChannel
