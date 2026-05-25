module Evergreen.V252.UserSession exposing (..)

import Effect.Http
import Evergreen.V252.Discord
import Evergreen.V252.Id
import Evergreen.V252.Message
import Evergreen.V252.SessionIdHash
import Evergreen.V252.UserAgent
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
    { userId : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute )
    , userAgent : Evergreen.V252.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V252.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.ThreadRoute )
    , userAgent : Evergreen.V252.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))))
    | ViewDmThread (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))))
    | ViewDiscordDm (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))))
    | ViewChannel (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))))
    | ViewChannelThread (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId) (Evergreen.V252.Message.Message Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))))
    | StopViewingChannel
