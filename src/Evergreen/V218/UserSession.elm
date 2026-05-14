module Evergreen.V218.UserSession exposing (..)

import Effect.Http
import Evergreen.V218.Discord
import Evergreen.V218.Id
import Evergreen.V218.Message
import Evergreen.V218.SessionIdHash
import Evergreen.V218.UserAgent
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
    { userId : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute )
    , userAgent : Evergreen.V218.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V218.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute )
    , userAgent : Evergreen.V218.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))))
    | ViewDmThread (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))))
    | ViewDiscordDm (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))))
    | ViewChannel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))))
    | ViewChannelThread (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))))
    | StopViewingChannel
