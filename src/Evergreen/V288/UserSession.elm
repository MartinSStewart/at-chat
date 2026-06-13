module Evergreen.V288.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V288.Discord
import Evergreen.V288.Id
import Evergreen.V288.Message
import Evergreen.V288.Ports
import Evergreen.V288.SessionIdHash
import Evergreen.V288.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V288.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V288.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute )
    , userAgent : Evergreen.V288.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V288.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.ThreadRoute )
    , userAgent : Evergreen.V288.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))))
    | ViewDmThread (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))))
    | ViewDiscordDm (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))))
    | ViewChannel (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))))
    | ViewChannelThread (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId) (Evergreen.V288.Message.Message Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))))
    | StopViewingChannel
