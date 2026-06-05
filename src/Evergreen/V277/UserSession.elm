module Evergreen.V277.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V277.Discord
import Evergreen.V277.Id
import Evergreen.V277.Message
import Evergreen.V277.Ports
import Evergreen.V277.SessionIdHash
import Evergreen.V277.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V277.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V277.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute )
    , userAgent : Evergreen.V277.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V277.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.ThreadRoute )
    , userAgent : Evergreen.V277.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))))
    | ViewDmThread (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))))
    | ViewDiscordDm (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))))
    | ViewChannel (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))))
    | ViewChannelThread (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId) (Evergreen.V277.Message.Message Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))))
    | StopViewingChannel
