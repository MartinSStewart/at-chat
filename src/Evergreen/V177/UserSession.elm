module Evergreen.V177.UserSession exposing (..)

import Effect.Http
import Evergreen.V177.Discord
import Evergreen.V177.Id
import Evergreen.V177.Message
import Evergreen.V177.SessionIdHash
import Evergreen.V177.UserAgent
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
    { userId : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute )
    , userAgent : Evergreen.V177.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V177.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute )
    , userAgent : Evergreen.V177.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))))
    | ViewDmThread (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))))
    | ViewDiscordDm (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))))
    | ViewChannel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))))
    | ViewChannelThread (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))))
    | StopViewingChannel
