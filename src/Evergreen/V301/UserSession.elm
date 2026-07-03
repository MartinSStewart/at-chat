module Evergreen.V301.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V301.Discord
import Evergreen.V301.FileStatus
import Evergreen.V301.Id
import Evergreen.V301.Message
import Evergreen.V301.PersonName
import Evergreen.V301.Ports
import Evergreen.V301.SessionIdHash
import Evergreen.V301.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V301.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V301.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V301.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V301.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V301.PersonName.PersonName
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute ))
    , userAgent : Evergreen.V301.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V301.Id.Id messageId) (Evergreen.V301.Message.Message messageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))))
    | ViewDmThread (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))))
    | ViewDiscordDm (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))))
    | ViewChannel (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))))
    | ViewChannelThread (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId) (Evergreen.V301.Message.Message Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V301.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V301.Id.ThreadMessageId))
    | StopViewingChannel
