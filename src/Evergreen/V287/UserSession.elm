module Evergreen.V287.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V287.Discord
import Evergreen.V287.Id
import Evergreen.V287.Message
import Evergreen.V287.Ports
import Evergreen.V287.SessionIdHash
import Evergreen.V287.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V287.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V287.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute )
    , userAgent : Evergreen.V287.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V287.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.ThreadRoute )
    , userAgent : Evergreen.V287.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))))
    | ViewDmThread (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))))
    | ViewDiscordDm (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))))
    | ViewChannel (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))))
    | ViewChannelThread (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId) (Evergreen.V287.Message.Message Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))))
    | StopViewingChannel
