module Evergreen.V283.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V283.Discord
import Evergreen.V283.Id
import Evergreen.V283.Message
import Evergreen.V283.Ports
import Evergreen.V283.SessionIdHash
import Evergreen.V283.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V283.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V283.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute )
    , userAgent : Evergreen.V283.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V283.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.ThreadRoute )
    , userAgent : Evergreen.V283.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))))
    | ViewDmThread (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))))
    | ViewDiscordDm (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))))
    | ViewChannel (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))))
    | ViewChannelThread (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId) (Evergreen.V283.Message.Message Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))))
    | StopViewingChannel
