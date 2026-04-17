module Evergreen.V203.UserSession exposing (..)

import Effect.Http
import Evergreen.V203.Discord
import Evergreen.V203.Id
import Evergreen.V203.Message
import Evergreen.V203.SessionIdHash
import Evergreen.V203.UserAgent
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
    { userId : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute )
    , userAgent : Evergreen.V203.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V203.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute )
    , userAgent : Evergreen.V203.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))))
    | ViewDmThread (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))))
    | ViewDiscordDm (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))))
    | ViewChannel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))))
    | ViewChannelThread (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))))
    | StopViewingChannel
