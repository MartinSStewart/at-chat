module Evergreen.V213.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Evergreen.V213.Discord
import Evergreen.V213.Id
import Evergreen.V213.Message
import Evergreen.V213.SessionIdHash
import Evergreen.V213.UserAgent
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
    { userId : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute )
    , userAgent : Evergreen.V213.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V213.SessionIdHash.SessionIdHash
    , clientId : Effect.Lamdera.ClientId
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute )
    , userAgent : Evergreen.V213.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))))
    | ViewDmThread (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))))
    | ViewDiscordDm (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))))
    | ViewChannel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))))
    | ViewChannelThread (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))))
    | StopViewingChannel
