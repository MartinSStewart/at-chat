module Evergreen.V149.UserSession exposing (..)

import Effect.Http
import Evergreen.V149.Discord
import Evergreen.V149.Id
import Evergreen.V149.Message
import Evergreen.V149.SessionIdHash
import Evergreen.V149.UserAgent
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
    { userId : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    , userAgent : Evergreen.V149.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V149.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.ThreadRoute )
    , userAgent : Evergreen.V149.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))))
    | ViewDmThread (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))))
    | ViewDiscordDm (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))))
    | ViewChannel (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))))
    | ViewChannelThread (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId) (Evergreen.V149.Message.Message Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))))
    | StopViewingChannel
