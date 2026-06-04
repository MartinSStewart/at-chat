module Evergreen.V271.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V271.Discord
import Evergreen.V271.Id
import Evergreen.V271.Message
import Evergreen.V271.Ports
import Evergreen.V271.SessionIdHash
import Evergreen.V271.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V271.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute )
    , userAgent : Evergreen.V271.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V271.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.ThreadRoute )
    , userAgent : Evergreen.V271.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))))
    | ViewDmThread (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))))
    | ViewDiscordDm (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))))
    | ViewChannel (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))))
    | ViewChannelThread (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId) (Evergreen.V271.Message.Message Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))))
    | StopViewingChannel
