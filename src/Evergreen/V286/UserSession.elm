module Evergreen.V286.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V286.Discord
import Evergreen.V286.Id
import Evergreen.V286.Message
import Evergreen.V286.Ports
import Evergreen.V286.SessionIdHash
import Evergreen.V286.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V286.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V286.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute )
    , userAgent : Evergreen.V286.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V286.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.ThreadRoute )
    , userAgent : Evergreen.V286.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))))
    | ViewDmThread (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))))
    | ViewDiscordDm (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))))
    | ViewChannel (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))))
    | ViewChannelThread (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId) (Evergreen.V286.Message.Message Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))))
    | StopViewingChannel
