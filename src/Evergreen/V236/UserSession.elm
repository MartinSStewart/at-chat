module Evergreen.V236.UserSession exposing (..)

import Effect.Http
import Evergreen.V236.Discord
import Evergreen.V236.Id
import Evergreen.V236.Message
import Evergreen.V236.SessionIdHash
import Evergreen.V236.UserAgent
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
    { userId : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute )
    , userAgent : Evergreen.V236.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V236.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.ThreadRoute )
    , userAgent : Evergreen.V236.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))))
    | ViewDmThread (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))))
    | ViewDiscordDm (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))))
    | ViewChannel (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))))
    | ViewChannelThread (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId) (Evergreen.V236.Message.Message Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))))
    | StopViewingChannel
