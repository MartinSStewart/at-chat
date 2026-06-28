module Evergreen.V295.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V295.Discord
import Evergreen.V295.FileStatus
import Evergreen.V295.Id
import Evergreen.V295.Message
import Evergreen.V295.PersonName
import Evergreen.V295.Ports
import Evergreen.V295.SessionIdHash
import Evergreen.V295.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V295.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V295.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute )
    , userAgent : Evergreen.V295.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V295.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V295.PersonName.PersonName
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.ThreadRoute )
    , userAgent : Evergreen.V295.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V295.Id.Id messageId) (Evergreen.V295.Message.Message messageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))))
    | ViewDmThread (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))))
    | ViewDiscordDm (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))))
    | ViewChannel (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))))
    | ViewChannelThread (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId) (Evergreen.V295.Message.Message Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V295.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V295.Id.ThreadMessageId))
    | StopViewingChannel
