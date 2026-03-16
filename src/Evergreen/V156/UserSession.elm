module Evergreen.V156.UserSession exposing (..)

import Effect.Http
import Evergreen.V156.Discord
import Evergreen.V156.Id
import Evergreen.V156.Message
import Evergreen.V156.SessionIdHash
import Evergreen.V156.UserAgent
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
    { userId : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    , userAgent : Evergreen.V156.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V156.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    , userAgent : Evergreen.V156.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))))
    | ViewDmThread (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))))
    | ViewDiscordDm (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))))
    | ViewChannel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))))
    | ViewChannelThread (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))))
    | StopViewingChannel
