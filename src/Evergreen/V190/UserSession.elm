module Evergreen.V190.UserSession exposing (..)

import Effect.Http
import Evergreen.V190.Discord
import Evergreen.V190.Id
import Evergreen.V190.Message
import Evergreen.V190.SessionIdHash
import Evergreen.V190.UserAgent
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
    { userId : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute )
    , userAgent : Evergreen.V190.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V190.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.ThreadRoute )
    , userAgent : Evergreen.V190.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))))
    | ViewDmThread (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))))
    | ViewDiscordDm (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))))
    | ViewChannel (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))))
    | ViewChannelThread (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId) (Evergreen.V190.Message.Message Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))))
    | StopViewingChannel
