module Evergreen.V229.UserSession exposing (..)

import Effect.Http
import Evergreen.V229.Discord
import Evergreen.V229.Id
import Evergreen.V229.Message
import Evergreen.V229.SessionIdHash
import Evergreen.V229.UserAgent
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
    { userId : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute )
    , userAgent : Evergreen.V229.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V229.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.ThreadRoute )
    , userAgent : Evergreen.V229.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))))
    | ViewDmThread (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))))
    | ViewDiscordDm (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))))
    | ViewChannel (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))))
    | ViewChannelThread (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId) (Evergreen.V229.Message.Message Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))))
    | StopViewingChannel
