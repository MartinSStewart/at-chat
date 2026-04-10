module Evergreen.V193.UserSession exposing (..)

import Effect.Http
import Evergreen.V193.Discord
import Evergreen.V193.Id
import Evergreen.V193.Message
import Evergreen.V193.SessionIdHash
import Evergreen.V193.UserAgent
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
    { userId : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute )
    , userAgent : Evergreen.V193.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V193.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute )
    , userAgent : Evergreen.V193.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))))
    | ViewDmThread (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))))
    | ViewDiscordDm (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))))
    | ViewChannel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))))
    | ViewChannelThread (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))))
    | StopViewingChannel
