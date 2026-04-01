module Evergreen.V184.UserSession exposing (..)

import Effect.Http
import Evergreen.V184.Discord
import Evergreen.V184.Id
import Evergreen.V184.Message
import Evergreen.V184.SessionIdHash
import Evergreen.V184.UserAgent
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
    { userId : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute )
    , userAgent : Evergreen.V184.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V184.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.ThreadRoute )
    , userAgent : Evergreen.V184.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))))
    | ViewDmThread (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))))
    | ViewDiscordDm (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))))
    | ViewChannel (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))))
    | ViewChannelThread (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId) (Evergreen.V184.Message.Message Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))))
    | StopViewingChannel
