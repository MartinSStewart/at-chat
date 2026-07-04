module Evergreen.V302.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V302.Discord
import Evergreen.V302.FileStatus
import Evergreen.V302.Id
import Evergreen.V302.Message
import Evergreen.V302.PersonName
import Evergreen.V302.Ports
import Evergreen.V302.SessionIdHash
import Evergreen.V302.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V302.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V302.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V302.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V302.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V302.PersonName.PersonName
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute ))
    , userAgent : Evergreen.V302.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V302.Id.Id messageId) (Evergreen.V302.Message.Message messageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))))
    | ViewDmThread (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))))
    | ViewDiscordDm (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))))
    | ViewChannel (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))))
    | ViewChannelThread (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId) (Evergreen.V302.Message.Message Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V302.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V302.Id.ThreadMessageId))
    | StopViewingChannel
