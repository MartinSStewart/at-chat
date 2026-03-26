module Evergreen.V171.UserSession exposing (..)

import Effect.Http
import Evergreen.V171.Discord
import Evergreen.V171.Id
import Evergreen.V171.Message
import Evergreen.V171.SessionIdHash
import Evergreen.V171.UserAgent
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
    { userId : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V171.Id.AnyGuildOrDmId, Evergreen.V171.Id.ThreadRoute )
    , userAgent : Evergreen.V171.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V171.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V171.Id.AnyGuildOrDmId, Evergreen.V171.Id.ThreadRoute )
    , userAgent : Evergreen.V171.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))))
    | ViewDmThread (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ThreadMessageId) (Evergreen.V171.Message.Message Evergreen.V171.Id.ThreadMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))))
    | ViewDiscordDm (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))))
    | ViewChannel (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))))
    | ViewChannelThread (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ThreadMessageId) (Evergreen.V171.Message.Message Evergreen.V171.Id.ThreadMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ThreadMessageId) (Evergreen.V171.Message.Message Evergreen.V171.Id.ThreadMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))))
    | StopViewingChannel
