module Evergreen.V279.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V279.Discord
import Evergreen.V279.Id
import Evergreen.V279.Message
import Evergreen.V279.Ports
import Evergreen.V279.SessionIdHash
import Evergreen.V279.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V279.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V279.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute )
    , userAgent : Evergreen.V279.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V279.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.ThreadRoute )
    , userAgent : Evergreen.V279.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))))
    | ViewDmThread (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))))
    | ViewDiscordDm (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))))
    | ViewChannel (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))))
    | ViewChannelThread (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId) (Evergreen.V279.Message.Message Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))))
    | StopViewingChannel
