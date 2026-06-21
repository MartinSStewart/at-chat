module Evergreen.V293.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V293.Discord
import Evergreen.V293.FileStatus
import Evergreen.V293.Id
import Evergreen.V293.Message
import Evergreen.V293.PersonName
import Evergreen.V293.Ports
import Evergreen.V293.SessionIdHash
import Evergreen.V293.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V293.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V293.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute )
    , userAgent : Evergreen.V293.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V293.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V293.PersonName.PersonName
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.ThreadRoute )
    , userAgent : Evergreen.V293.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V293.Id.Id messageId) (Evergreen.V293.Message.Message messageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))))
    | ViewDmThread (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ThreadMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))))
    | ViewDiscordDm (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))))
    | ViewChannel (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))))
    | ViewChannelThread (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId) (Evergreen.V293.Message.Message Evergreen.V293.Id.ThreadMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V293.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V293.Id.ThreadMessageId))
    | StopViewingChannel
