module Evergreen.V199.UserSession exposing (..)

import Effect.Http
import Evergreen.V199.Discord
import Evergreen.V199.Id
import Evergreen.V199.Message
import Evergreen.V199.SessionIdHash
import Evergreen.V199.UserAgent
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
    { userId : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute )
    , userAgent : Evergreen.V199.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V199.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute )
    , userAgent : Evergreen.V199.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))))
    | ViewDmThread (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))))
    | ViewDiscordDm (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))))
    | ViewChannel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))))
    | ViewChannelThread (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))))
    | StopViewingChannel
