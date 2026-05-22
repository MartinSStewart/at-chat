module Evergreen.V247.UserSession exposing (..)

import Effect.Http
import Evergreen.V247.Discord
import Evergreen.V247.Id
import Evergreen.V247.Message
import Evergreen.V247.SessionIdHash
import Evergreen.V247.UserAgent
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
    { userId : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute )
    , userAgent : Evergreen.V247.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V247.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.ThreadRoute )
    , userAgent : Evergreen.V247.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))))
    | ViewDmThread (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))))
    | ViewDiscordDm (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))))
    | ViewChannel (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))))
    | ViewChannelThread (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId) (Evergreen.V247.Message.Message Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))))
    | StopViewingChannel
