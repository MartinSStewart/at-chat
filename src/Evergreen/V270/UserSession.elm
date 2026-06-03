module Evergreen.V270.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V270.Discord
import Evergreen.V270.Id
import Evergreen.V270.Message
import Evergreen.V270.SessionIdHash
import Evergreen.V270.UserAgent
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
    { userId : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute )
    , userAgent : Evergreen.V270.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V270.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.ThreadRoute )
    , userAgent : Evergreen.V270.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))))
    | ViewDmThread (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))))
    | ViewDiscordDm (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))))
    | ViewChannel (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))))
    | ViewChannelThread (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId) (Evergreen.V270.Message.Message Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))))
    | StopViewingChannel
