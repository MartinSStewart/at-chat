module Evergreen.V262.UserSession exposing (..)

import Effect.Http
import Evergreen.V262.Discord
import Evergreen.V262.Id
import Evergreen.V262.Message
import Evergreen.V262.SessionIdHash
import Evergreen.V262.UserAgent
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
    { userId : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V262.Id.AnyGuildOrDmId, Evergreen.V262.Id.ThreadRoute )
    , userAgent : Evergreen.V262.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V262.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V262.Id.AnyGuildOrDmId, Evergreen.V262.Id.ThreadRoute )
    , userAgent : Evergreen.V262.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))))
    | ViewDmThread (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ThreadMessageId) (Evergreen.V262.Message.Message Evergreen.V262.Id.ThreadMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))))
    | ViewDiscordDm (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))))
    | ViewChannel (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))))
    | ViewChannelThread (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ThreadMessageId) (Evergreen.V262.Message.Message Evergreen.V262.Id.ThreadMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ThreadMessageId) (Evergreen.V262.Message.Message Evergreen.V262.Id.ThreadMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))))
    | StopViewingChannel
