module Evergreen.V209.UserSession exposing (..)

import Effect.Http
import Evergreen.V209.Discord
import Evergreen.V209.Id
import Evergreen.V209.Message
import Evergreen.V209.SessionIdHash
import Evergreen.V209.UserAgent
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
    { userId : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute )
    , userAgent : Evergreen.V209.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V209.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute )
    , userAgent : Evergreen.V209.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))))
    | ViewDmThread (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))))
    | ViewDiscordDm (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))))
    | ViewChannel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))))
    | ViewChannelThread (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))))
    | StopViewingChannel
