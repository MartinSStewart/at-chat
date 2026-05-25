module Evergreen.V251.UserSession exposing (..)

import Effect.Http
import Evergreen.V251.Discord
import Evergreen.V251.Id
import Evergreen.V251.Message
import Evergreen.V251.SessionIdHash
import Evergreen.V251.UserAgent
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
    { userId : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute )
    , userAgent : Evergreen.V251.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V251.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.ThreadRoute )
    , userAgent : Evergreen.V251.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))))
    | ViewDmThread (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))))
    | ViewDiscordDm (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))))
    | ViewChannel (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))))
    | ViewChannelThread (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId) (Evergreen.V251.Message.Message Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))))
    | StopViewingChannel
