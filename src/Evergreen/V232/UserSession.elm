module Evergreen.V232.UserSession exposing (..)

import Effect.Http
import Evergreen.V232.Discord
import Evergreen.V232.Id
import Evergreen.V232.Message
import Evergreen.V232.SessionIdHash
import Evergreen.V232.UserAgent
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
    { userId : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute )
    , userAgent : Evergreen.V232.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V232.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.ThreadRoute )
    , userAgent : Evergreen.V232.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))))
    | ViewDmThread (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))))
    | ViewDiscordDm (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))))
    | ViewChannel (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))))
    | ViewChannelThread (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId) (Evergreen.V232.Message.Message Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))))
    | StopViewingChannel
