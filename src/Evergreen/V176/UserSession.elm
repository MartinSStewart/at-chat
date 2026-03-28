module Evergreen.V176.UserSession exposing (..)

import Effect.Http
import Evergreen.V176.Discord
import Evergreen.V176.Id
import Evergreen.V176.Message
import Evergreen.V176.SessionIdHash
import Evergreen.V176.UserAgent
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
    { userId : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute )
    , userAgent : Evergreen.V176.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V176.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute )
    , userAgent : Evergreen.V176.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))))
    | ViewDmThread (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))))
    | ViewDiscordDm (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))))
    | ViewChannel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))))
    | ViewChannelThread (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))))
    | StopViewingChannel
