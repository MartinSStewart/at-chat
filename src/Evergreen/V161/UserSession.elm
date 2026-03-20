module Evergreen.V161.UserSession exposing (..)

import Effect.Http
import Evergreen.V161.Discord
import Evergreen.V161.Id
import Evergreen.V161.Message
import Evergreen.V161.SessionIdHash
import Evergreen.V161.UserAgent
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
    { userId : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute )
    , userAgent : Evergreen.V161.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V161.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.ThreadRoute )
    , userAgent : Evergreen.V161.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))))
    | ViewDmThread (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))))
    | ViewDiscordDm (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))))
    | ViewChannel (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))))
    | ViewChannelThread (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId) (Evergreen.V161.Message.Message Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))))
    | StopViewingChannel
