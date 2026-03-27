module Evergreen.V173.UserSession exposing (..)

import Effect.Http
import Evergreen.V173.Discord
import Evergreen.V173.Id
import Evergreen.V173.Message
import Evergreen.V173.SessionIdHash
import Evergreen.V173.UserAgent
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
    { userId : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute )
    , userAgent : Evergreen.V173.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V173.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute )
    , userAgent : Evergreen.V173.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))))
    | ViewDmThread (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))))
    | ViewDiscordDm (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))))
    | ViewChannel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))))
    | ViewChannelThread (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))))
    | StopViewingChannel
