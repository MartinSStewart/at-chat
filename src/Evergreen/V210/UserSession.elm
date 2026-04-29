module Evergreen.V210.UserSession exposing (..)

import Effect.Http
import Evergreen.V210.Discord
import Evergreen.V210.Id
import Evergreen.V210.Message
import Evergreen.V210.SessionIdHash
import Evergreen.V210.UserAgent
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
    { userId : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute )
    , userAgent : Evergreen.V210.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V210.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute )
    , userAgent : Evergreen.V210.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))))
    | ViewDmThread (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))))
    | ViewDiscordDm (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))))
    | ViewChannel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))))
    | ViewChannelThread (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))))
    | StopViewingChannel
