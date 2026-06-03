module Evergreen.V269.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V269.Discord
import Evergreen.V269.Id
import Evergreen.V269.Message
import Evergreen.V269.SessionIdHash
import Evergreen.V269.UserAgent
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
    { userId : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute )
    , userAgent : Evergreen.V269.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V269.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.ThreadRoute )
    , userAgent : Evergreen.V269.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))))
    | ViewDmThread (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))))
    | ViewDiscordDm (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))))
    | ViewChannel (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))))
    | ViewChannelThread (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId) (Evergreen.V269.Message.Message Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))))
    | StopViewingChannel
