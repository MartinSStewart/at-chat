module Evergreen.V154.UserSession exposing (..)

import Effect.Http
import Evergreen.V154.Discord
import Evergreen.V154.Id
import Evergreen.V154.Message
import Evergreen.V154.SessionIdHash
import Evergreen.V154.UserAgent
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
    { userId : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    , userAgent : Evergreen.V154.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V154.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    , userAgent : Evergreen.V154.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))))
    | ViewDmThread (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))))
    | ViewDiscordDm (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))))
    | ViewChannel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))))
    | ViewChannelThread (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))))
    | StopViewingChannel
