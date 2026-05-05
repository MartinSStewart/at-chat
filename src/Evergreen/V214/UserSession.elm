module Evergreen.V214.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Evergreen.V214.Discord
import Evergreen.V214.Id
import Evergreen.V214.Message
import Evergreen.V214.SessionIdHash
import Evergreen.V214.UserAgent
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
    { userId : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V214.Id.AnyGuildOrDmId, Evergreen.V214.Id.ThreadRoute )
    , userAgent : Evergreen.V214.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V214.SessionIdHash.SessionIdHash
    , clientId : Effect.Lamdera.ClientId
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V214.Id.AnyGuildOrDmId, Evergreen.V214.Id.ThreadRoute )
    , userAgent : Evergreen.V214.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))))
    | ViewDmThread (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ThreadMessageId) (Evergreen.V214.Message.Message Evergreen.V214.Id.ThreadMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))))
    | ViewDiscordDm (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))))
    | ViewChannel (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))))
    | ViewChannelThread (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ThreadMessageId) (Evergreen.V214.Message.Message Evergreen.V214.Id.ThreadMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ThreadMessageId) (Evergreen.V214.Message.Message Evergreen.V214.Id.ThreadMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))))
    | StopViewingChannel
