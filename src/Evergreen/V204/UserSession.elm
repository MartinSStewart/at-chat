module Evergreen.V204.UserSession exposing (..)

import Effect.Http
import Evergreen.V204.Discord
import Evergreen.V204.Id
import Evergreen.V204.Message
import Evergreen.V204.SessionIdHash
import Evergreen.V204.UserAgent
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
    { userId : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute )
    , userAgent : Evergreen.V204.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V204.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute )
    , userAgent : Evergreen.V204.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))))
    | ViewDmThread (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))))
    | ViewDiscordDm (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))))
    | ViewChannel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))))
    | ViewChannelThread (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))))
    | StopViewingChannel
