module Evergreen.V136.UserSession exposing (..)

import Effect.Http
import Evergreen.V136.Discord.Id
import Evergreen.V136.Id
import Evergreen.V136.Message
import Evergreen.V136.SessionIdHash
import Evergreen.V136.UserAgent
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
    { userId : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    , userAgent : Evergreen.V136.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V136.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    , userAgent : Evergreen.V136.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))))
    | ViewDmThread (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))))
    | ViewDiscordDm (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))))
    | ViewChannelThread (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))))
    | StopViewingChannel
