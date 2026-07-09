module Evergreen.V308.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V308.Discord
import Evergreen.V308.FileStatus
import Evergreen.V308.Id
import Evergreen.V308.Message
import Evergreen.V308.PersonName
import Evergreen.V308.Ports
import Evergreen.V308.SessionIdHash
import Evergreen.V308.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V308.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V308.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V308.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V308.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V308.PersonName.PersonName
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute ))
    , userAgent : Evergreen.V308.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V308.Id.Id messageId) (Evergreen.V308.Message.Message messageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))))
    | ViewDmThread (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))))
    | ViewDiscordDm (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))))
    | ViewChannel (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))))
    | ViewChannelThread (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId) (Evergreen.V308.Message.Message Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V308.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V308.Id.ThreadMessageId))
    | StopViewingChannel
