module Evergreen.V147.UserSession exposing (..)

import Effect.Http
import Evergreen.V147.Discord
import Evergreen.V147.Id
import Evergreen.V147.Message
import Evergreen.V147.SessionIdHash
import Evergreen.V147.UserAgent
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
    { userId : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    , userAgent : Evergreen.V147.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V147.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.ThreadRoute )
    , userAgent : Evergreen.V147.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))))
    | ViewDmThread (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))))
    | ViewDiscordDm (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))))
    | ViewChannel (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))))
    | ViewChannelThread (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId) (Evergreen.V147.Message.Message Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))))
    | StopViewingChannel
