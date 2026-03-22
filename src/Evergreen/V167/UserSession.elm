module Evergreen.V167.UserSession exposing (..)

import Effect.Http
import Evergreen.V167.Discord
import Evergreen.V167.Id
import Evergreen.V167.Message
import Evergreen.V167.SessionIdHash
import Evergreen.V167.UserAgent
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
    { userId : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute )
    , userAgent : Evergreen.V167.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V167.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.ThreadRoute )
    , userAgent : Evergreen.V167.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))))
    | ViewDmThread (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))))
    | ViewDiscordDm (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))))
    | ViewChannel (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))))
    | ViewChannelThread (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId) (Evergreen.V167.Message.Message Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))))
    | StopViewingChannel
