module Evergreen.V207.UserSession exposing (..)

import Effect.Http
import Evergreen.V207.Discord
import Evergreen.V207.Id
import Evergreen.V207.Message
import Evergreen.V207.SessionIdHash
import Evergreen.V207.UserAgent
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
    { userId : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute )
    , userAgent : Evergreen.V207.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V207.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute )
    , userAgent : Evergreen.V207.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))))
    | ViewDmThread (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))))
    | ViewDiscordDm (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))))
    | ViewChannel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))))
    | ViewChannelThread (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))))
    | StopViewingChannel
