module Evergreen.V315.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V315.Discord
import Evergreen.V315.FileStatus
import Evergreen.V315.Id
import Evergreen.V315.Message
import Evergreen.V315.PersonName
import Evergreen.V315.Ports
import Evergreen.V315.SessionIdHash
import Evergreen.V315.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V315.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V315.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V315.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V315.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V315.PersonName.PersonName
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute ))
    , userAgent : Evergreen.V315.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V315.Id.Id messageId) (Evergreen.V315.Message.Message messageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))))
    | ViewDmThread (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))))
    | ViewDiscordDm (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))))
    | ViewChannel (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))))
    | ViewChannelThread (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId) (Evergreen.V315.Message.Message Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V315.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V315.Id.ThreadMessageId))
    | StopViewingChannel
