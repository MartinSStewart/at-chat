module Evergreen.V299.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V299.Discord
import Evergreen.V299.FileStatus
import Evergreen.V299.Id
import Evergreen.V299.Message
import Evergreen.V299.PersonName
import Evergreen.V299.Ports
import Evergreen.V299.SessionIdHash
import Evergreen.V299.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V299.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V299.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute )
    , userAgent : Evergreen.V299.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V299.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V299.PersonName.PersonName
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.ThreadRoute )
    , userAgent : Evergreen.V299.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V299.Id.Id messageId) (Evergreen.V299.Message.Message messageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))))
    | ViewDmThread (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))))
    | ViewDiscordDm (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))))
    | ViewChannel (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))))
    | ViewChannelThread (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId) (Evergreen.V299.Message.Message Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V299.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V299.Id.ThreadMessageId))
    | StopViewingChannel
