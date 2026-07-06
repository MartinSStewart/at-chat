module Evergreen.V304.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V304.Discord
import Evergreen.V304.FileStatus
import Evergreen.V304.Id
import Evergreen.V304.Message
import Evergreen.V304.PersonName
import Evergreen.V304.Ports
import Evergreen.V304.SessionIdHash
import Evergreen.V304.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V304.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V304.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V304.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V304.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V304.PersonName.PersonName
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute ))
    , userAgent : Evergreen.V304.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V304.Id.Id messageId) (Evergreen.V304.Message.Message messageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))))
    | ViewDmThread (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))))
    | ViewDiscordDm (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))))
    | ViewChannel (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))))
    | ViewChannelThread (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId) (Evergreen.V304.Message.Message Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V304.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V304.Id.ThreadMessageId))
    | StopViewingChannel
