module Evergreen.V118.UserSession exposing (..)

import Effect.Http
import Evergreen.V118.Discord.Id
import Evergreen.V118.Id
import Evergreen.V118.Message
import Evergreen.V118.SessionIdHash
import Evergreen.V118.UserAgent
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
    { userId : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    , userAgent : Evergreen.V118.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V118.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.ThreadRoute )
    , userAgent : Evergreen.V118.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))))
    | ViewDmThread (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))))
    | ViewDiscordDm (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))))
    | ViewChannelThread (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId) (Evergreen.V118.Message.Message Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))))
    | StopViewingChannel
