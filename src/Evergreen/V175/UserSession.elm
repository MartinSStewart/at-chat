module Evergreen.V175.UserSession exposing (..)

import Effect.Http
import Evergreen.V175.Discord
import Evergreen.V175.Id
import Evergreen.V175.Message
import Evergreen.V175.SessionIdHash
import Evergreen.V175.UserAgent
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
    { userId : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute )
    , userAgent : Evergreen.V175.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V175.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute )
    , userAgent : Evergreen.V175.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))))
    | ViewDmThread (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))))
    | ViewDiscordDm (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))))
    | ViewChannel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))))
    | ViewChannelThread (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))))
    | StopViewingChannel
