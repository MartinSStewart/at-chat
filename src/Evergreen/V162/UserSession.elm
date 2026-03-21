module Evergreen.V162.UserSession exposing (..)

import Effect.Http
import Evergreen.V162.Discord
import Evergreen.V162.Id
import Evergreen.V162.Message
import Evergreen.V162.SessionIdHash
import Evergreen.V162.UserAgent
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
    { userId : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V162.Id.AnyGuildOrDmId, Evergreen.V162.Id.ThreadRoute )
    , userAgent : Evergreen.V162.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V162.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V162.Id.AnyGuildOrDmId, Evergreen.V162.Id.ThreadRoute )
    , userAgent : Evergreen.V162.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))))
    | ViewDmThread (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ThreadMessageId) (Evergreen.V162.Message.Message Evergreen.V162.Id.ThreadMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))))
    | ViewDiscordDm (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))))
    | ViewChannel (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))))
    | ViewChannelThread (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ThreadMessageId) (Evergreen.V162.Message.Message Evergreen.V162.Id.ThreadMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ThreadMessageId) (Evergreen.V162.Message.Message Evergreen.V162.Id.ThreadMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))))
    | StopViewingChannel
