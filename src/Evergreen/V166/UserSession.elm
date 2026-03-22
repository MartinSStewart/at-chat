module Evergreen.V166.UserSession exposing (..)

import Effect.Http
import Evergreen.V166.Discord
import Evergreen.V166.Id
import Evergreen.V166.Message
import Evergreen.V166.SessionIdHash
import Evergreen.V166.UserAgent
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
    { userId : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute )
    , userAgent : Evergreen.V166.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V166.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.ThreadRoute )
    , userAgent : Evergreen.V166.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))))
    | ViewDmThread (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))))
    | ViewDiscordDm (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))))
    | ViewChannel (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))))
    | ViewChannelThread (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId) (Evergreen.V166.Message.Message Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))))
    | StopViewingChannel
