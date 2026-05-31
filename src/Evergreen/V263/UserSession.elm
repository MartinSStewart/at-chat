module Evergreen.V263.UserSession exposing (..)

import Effect.Http
import Evergreen.V263.Discord
import Evergreen.V263.Id
import Evergreen.V263.Message
import Evergreen.V263.SessionIdHash
import Evergreen.V263.UserAgent
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
    { userId : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute )
    , userAgent : Evergreen.V263.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V263.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.ThreadRoute )
    , userAgent : Evergreen.V263.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))))
    | ViewDmThread (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))))
    | ViewDiscordDm (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))))
    | ViewChannel (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))))
    | ViewChannelThread (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId) (Evergreen.V263.Message.Message Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))))
    | StopViewingChannel
