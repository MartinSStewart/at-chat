module Evergreen.V250.UserSession exposing (..)

import Effect.Http
import Evergreen.V250.Discord
import Evergreen.V250.Id
import Evergreen.V250.Message
import Evergreen.V250.SessionIdHash
import Evergreen.V250.UserAgent
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
    { userId : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute )
    , userAgent : Evergreen.V250.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V250.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.ThreadRoute )
    , userAgent : Evergreen.V250.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))))
    | ViewDmThread (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))))
    | ViewDiscordDm (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))))
    | ViewChannel (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))))
    | ViewChannelThread (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId) (Evergreen.V250.Message.Message Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))))
    | StopViewingChannel
