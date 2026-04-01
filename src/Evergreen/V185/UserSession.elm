module Evergreen.V185.UserSession exposing (..)

import Effect.Http
import Evergreen.V185.Discord
import Evergreen.V185.Id
import Evergreen.V185.Message
import Evergreen.V185.SessionIdHash
import Evergreen.V185.UserAgent
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
    { userId : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute )
    , userAgent : Evergreen.V185.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V185.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.ThreadRoute )
    , userAgent : Evergreen.V185.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))))
    | ViewDmThread (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))))
    | ViewDiscordDm (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))))
    | ViewChannel (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))))
    | ViewChannelThread (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId) (Evergreen.V185.Message.Message Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))))
    | StopViewingChannel
