module Evergreen.V254.UserSession exposing (..)

import Effect.Http
import Evergreen.V254.Discord
import Evergreen.V254.Id
import Evergreen.V254.Message
import Evergreen.V254.SessionIdHash
import Evergreen.V254.UserAgent
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
    { userId : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V254.Id.AnyGuildOrDmId, Evergreen.V254.Id.ThreadRoute )
    , userAgent : Evergreen.V254.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V254.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V254.Id.AnyGuildOrDmId, Evergreen.V254.Id.ThreadRoute )
    , userAgent : Evergreen.V254.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))))
    | ViewDmThread (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ThreadMessageId) (Evergreen.V254.Message.Message Evergreen.V254.Id.ThreadMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))))
    | ViewDiscordDm (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))))
    | ViewChannel (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))))
    | ViewChannelThread (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ThreadMessageId) (Evergreen.V254.Message.Message Evergreen.V254.Id.ThreadMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ThreadMessageId) (Evergreen.V254.Message.Message Evergreen.V254.Id.ThreadMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))))
    | StopViewingChannel
