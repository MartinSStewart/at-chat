module Evergreen.V289.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V289.Discord
import Evergreen.V289.Id
import Evergreen.V289.Message
import Evergreen.V289.Ports
import Evergreen.V289.SessionIdHash
import Evergreen.V289.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V289.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V289.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute )
    , userAgent : Evergreen.V289.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V289.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.ThreadRoute )
    , userAgent : Evergreen.V289.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))))
    | ViewDmThread (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))))
    | ViewDiscordDm (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))))
    | ViewChannel (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))))
    | ViewChannelThread (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId) (Evergreen.V289.Message.Message Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))))
    | StopViewingChannel
