module Evergreen.V297.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V297.Discord
import Evergreen.V297.FileStatus
import Evergreen.V297.Id
import Evergreen.V297.Message
import Evergreen.V297.PersonName
import Evergreen.V297.Ports
import Evergreen.V297.SessionIdHash
import Evergreen.V297.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V297.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V297.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute )
    , userAgent : Evergreen.V297.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V297.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V297.PersonName.PersonName
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.ThreadRoute )
    , userAgent : Evergreen.V297.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V297.Id.Id messageId) (Evergreen.V297.Message.Message messageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))))
    | ViewDmThread (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))))
    | ViewDiscordDm (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))))
    | ViewChannel (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))))
    | ViewChannelThread (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId) (Evergreen.V297.Message.Message Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V297.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V297.Id.ThreadMessageId))
    | StopViewingChannel
