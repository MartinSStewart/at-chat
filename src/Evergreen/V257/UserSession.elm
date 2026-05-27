module Evergreen.V257.UserSession exposing (..)

import Effect.Http
import Evergreen.V257.Discord
import Evergreen.V257.Id
import Evergreen.V257.Message
import Evergreen.V257.SessionIdHash
import Evergreen.V257.UserAgent
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
    { userId : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute )
    , userAgent : Evergreen.V257.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V257.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.ThreadRoute )
    , userAgent : Evergreen.V257.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))))
    | ViewDmThread (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))))
    | ViewDiscordDm (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))))
    | ViewChannel (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))))
    | ViewChannelThread (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId) (Evergreen.V257.Message.Message Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))))
    | StopViewingChannel
