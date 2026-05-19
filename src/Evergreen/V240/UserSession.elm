module Evergreen.V240.UserSession exposing (..)

import Effect.Http
import Evergreen.V240.Discord
import Evergreen.V240.Id
import Evergreen.V240.Message
import Evergreen.V240.SessionIdHash
import Evergreen.V240.UserAgent
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
    { userId : Evergreen.V240.Id.Id Evergreen.V240.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute )
    , userAgent : Evergreen.V240.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V240.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.ThreadRoute )
    , userAgent : Evergreen.V240.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))))
    | ViewDmThread (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))))
    | ViewDiscordDm (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))))
    | ViewChannel (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))))
    | ViewChannelThread (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId) (Evergreen.V240.Message.Message Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))))
    | StopViewingChannel
