module Evergreen.V187.UserSession exposing (..)

import Effect.Http
import Evergreen.V187.Discord
import Evergreen.V187.Id
import Evergreen.V187.Message
import Evergreen.V187.SessionIdHash
import Evergreen.V187.UserAgent
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
    { userId : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute )
    , userAgent : Evergreen.V187.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V187.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.ThreadRoute )
    , userAgent : Evergreen.V187.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))))
    | ViewDmThread (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))))
    | ViewDiscordDm (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))))
    | ViewChannel (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))))
    | ViewChannelThread (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId) (Evergreen.V187.Message.Message Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))))
    | StopViewingChannel
