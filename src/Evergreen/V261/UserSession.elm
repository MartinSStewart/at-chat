module Evergreen.V261.UserSession exposing (..)

import Effect.Http
import Evergreen.V261.Discord
import Evergreen.V261.Id
import Evergreen.V261.Message
import Evergreen.V261.SessionIdHash
import Evergreen.V261.UserAgent
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
    { userId : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute )
    , userAgent : Evergreen.V261.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V261.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.ThreadRoute )
    , userAgent : Evergreen.V261.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))))
    | ViewDmThread (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))))
    | ViewDiscordDm (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))))
    | ViewChannel (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))))
    | ViewChannelThread (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId) (Evergreen.V261.Message.Message Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))))
    | StopViewingChannel
