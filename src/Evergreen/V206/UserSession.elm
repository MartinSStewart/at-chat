module Evergreen.V206.UserSession exposing (..)

import Effect.Http
import Evergreen.V206.Discord
import Evergreen.V206.Id
import Evergreen.V206.Message
import Evergreen.V206.SessionIdHash
import Evergreen.V206.UserAgent
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
    { userId : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute )
    , userAgent : Evergreen.V206.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V206.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute )
    , userAgent : Evergreen.V206.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))))
    | ViewDmThread (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))))
    | ViewDiscordDm (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))))
    | ViewChannel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))))
    | ViewChannelThread (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))))
    | StopViewingChannel
