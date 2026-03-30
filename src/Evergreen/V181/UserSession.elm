module Evergreen.V181.UserSession exposing (..)

import Effect.Http
import Evergreen.V181.Discord
import Evergreen.V181.Id
import Evergreen.V181.Message
import Evergreen.V181.SessionIdHash
import Evergreen.V181.UserAgent
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
    { userId : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute )
    , userAgent : Evergreen.V181.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V181.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute )
    , userAgent : Evergreen.V181.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))))
    | ViewDmThread (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))))
    | ViewDiscordDm (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))))
    | ViewChannel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))))
    | ViewChannelThread (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))))
    | StopViewingChannel
