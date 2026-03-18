module Evergreen.V158.UserSession exposing (..)

import Effect.Http
import Evergreen.V158.Discord
import Evergreen.V158.Id
import Evergreen.V158.Message
import Evergreen.V158.SessionIdHash
import Evergreen.V158.UserAgent
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
    { userId : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    , userAgent : Evergreen.V158.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V158.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.ThreadRoute )
    , userAgent : Evergreen.V158.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))))
    | ViewDmThread (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))))
    | ViewDiscordDm (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))))
    | ViewChannel (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))))
    | ViewChannelThread (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId) (Evergreen.V158.Message.Message Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))))
    | StopViewingChannel
