module Evergreen.V215.UserSession exposing (..)

import Effect.Http
import Evergreen.V215.Discord
import Evergreen.V215.Id
import Evergreen.V215.Message
import Evergreen.V215.SessionIdHash
import Evergreen.V215.UserAgent
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
    { userId : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute )
    , userAgent : Evergreen.V215.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V215.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute )
    , userAgent : Evergreen.V215.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))))
    | ViewDmThread (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))))
    | ViewDiscordDm (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))))
    | ViewChannel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))))
    | ViewChannelThread (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))))
    | StopViewingChannel
