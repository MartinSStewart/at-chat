module Evergreen.V119.UserSession exposing (..)

import Effect.Http
import Evergreen.V119.Discord.Id
import Evergreen.V119.Id
import Evergreen.V119.Message
import Evergreen.V119.SessionIdHash
import Evergreen.V119.UserAgent
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
    { userId : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    , userAgent : Evergreen.V119.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V119.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.ThreadRoute )
    , userAgent : Evergreen.V119.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))))
    | ViewDmThread (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))))
    | ViewDiscordDm (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))))
    | ViewChannelThread (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId) (Evergreen.V119.Message.Message Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))))
    | StopViewingChannel
