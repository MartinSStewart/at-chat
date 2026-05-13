module Evergreen.V216.UserSession exposing (..)

import Effect.Http
import Evergreen.V216.Discord
import Evergreen.V216.Id
import Evergreen.V216.Message
import Evergreen.V216.SessionIdHash
import Evergreen.V216.UserAgent
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
    { userId : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute )
    , userAgent : Evergreen.V216.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V216.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute )
    , userAgent : Evergreen.V216.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))))
    | ViewDmThread (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))))
    | ViewDiscordDm (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))))
    | ViewChannel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))))
    | ViewChannelThread (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))))
    | StopViewingChannel
