module Evergreen.V285.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V285.Discord
import Evergreen.V285.Id
import Evergreen.V285.Message
import Evergreen.V285.Ports
import Evergreen.V285.SessionIdHash
import Evergreen.V285.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V285.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V285.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute )
    , userAgent : Evergreen.V285.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V285.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.ThreadRoute )
    , userAgent : Evergreen.V285.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))))
    | ViewDmThread (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))))
    | ViewDiscordDm (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))))
    | ViewChannel (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))))
    | ViewChannelThread (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId) (Evergreen.V285.Message.Message Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))))
    | StopViewingChannel
