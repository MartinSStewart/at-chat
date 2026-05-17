module Evergreen.V228.UserSession exposing (..)

import Effect.Http
import Evergreen.V228.Discord
import Evergreen.V228.Id
import Evergreen.V228.Message
import Evergreen.V228.SessionIdHash
import Evergreen.V228.UserAgent
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
    { userId : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute )
    , userAgent : Evergreen.V228.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V228.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.ThreadRoute )
    , userAgent : Evergreen.V228.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))))
    | ViewDmThread (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))))
    | ViewDiscordDm (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))))
    | ViewChannel (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))))
    | ViewChannelThread (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId) (Evergreen.V228.Message.Message Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))))
    | StopViewingChannel
