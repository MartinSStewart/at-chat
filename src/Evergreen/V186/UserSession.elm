module Evergreen.V186.UserSession exposing (..)

import Effect.Http
import Evergreen.V186.Discord
import Evergreen.V186.Id
import Evergreen.V186.Message
import Evergreen.V186.SessionIdHash
import Evergreen.V186.UserAgent
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
    { userId : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute )
    , userAgent : Evergreen.V186.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V186.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.ThreadRoute )
    , userAgent : Evergreen.V186.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))))
    | ViewDmThread (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))))
    | ViewDiscordDm (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))))
    | ViewChannel (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))))
    | ViewChannelThread (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId) (Evergreen.V186.Message.Message Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))))
    | StopViewingChannel
