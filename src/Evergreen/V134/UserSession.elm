module Evergreen.V134.UserSession exposing (..)

import Effect.Http
import Evergreen.V134.Discord.Id
import Evergreen.V134.Id
import Evergreen.V134.Message
import Evergreen.V134.SessionIdHash
import Evergreen.V134.UserAgent
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
    { userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    , userAgent : Evergreen.V134.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V134.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    , userAgent : Evergreen.V134.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))))
    | ViewDmThread (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))))
    | ViewDiscordDm (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))))
    | ViewChannelThread (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))))
    | StopViewingChannel
