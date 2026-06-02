module Evergreen.V264.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V264.Discord
import Evergreen.V264.Id
import Evergreen.V264.Message
import Evergreen.V264.SessionIdHash
import Evergreen.V264.UserAgent
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
    | Subscribed SubscribeData Effect.Time.Posix
    | SubscriptionError Effect.Http.Error


type alias UserSession =
    { userId : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute )
    , userAgent : Evergreen.V264.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V264.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.ThreadRoute )
    , userAgent : Evergreen.V264.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))))
    | ViewDmThread (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))))
    | ViewDiscordDm (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))))
    | ViewChannel (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))))
    | ViewChannelThread (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId) (Evergreen.V264.Message.Message Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))))
    | StopViewingChannel
