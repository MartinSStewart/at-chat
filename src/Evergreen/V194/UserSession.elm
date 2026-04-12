module Evergreen.V194.UserSession exposing (..)

import Effect.Http
import Evergreen.V194.Discord
import Evergreen.V194.Id
import Evergreen.V194.Message
import Evergreen.V194.SessionIdHash
import Evergreen.V194.UserAgent
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
    { userId : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute )
    , userAgent : Evergreen.V194.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V194.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute )
    , userAgent : Evergreen.V194.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))))
    | ViewDmThread (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))))
    | ViewDiscordDm (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))))
    | ViewChannel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))))
    | ViewChannelThread (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))))
    | StopViewingChannel
