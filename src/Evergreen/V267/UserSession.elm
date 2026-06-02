module Evergreen.V267.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V267.Discord
import Evergreen.V267.Id
import Evergreen.V267.Message
import Evergreen.V267.SessionIdHash
import Evergreen.V267.UserAgent
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
    { userId : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute )
    , userAgent : Evergreen.V267.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V267.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.ThreadRoute )
    , userAgent : Evergreen.V267.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))))
    | ViewDmThread (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))))
    | ViewDiscordDm (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))))
    | ViewChannel (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))))
    | ViewChannelThread (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId) (Evergreen.V267.Message.Message Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))))
    | StopViewingChannel
