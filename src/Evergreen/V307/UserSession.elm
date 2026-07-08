module Evergreen.V307.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V307.Discord
import Evergreen.V307.FileStatus
import Evergreen.V307.Id
import Evergreen.V307.Message
import Evergreen.V307.PersonName
import Evergreen.V307.Ports
import Evergreen.V307.SessionIdHash
import Evergreen.V307.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V307.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V307.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V307.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V307.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V307.PersonName.PersonName
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute ))
    , userAgent : Evergreen.V307.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V307.Id.Id messageId) (Evergreen.V307.Message.Message messageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))))
    | ViewDmThread (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))))
    | ViewDiscordDm (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))))
    | ViewChannel (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))))
    | ViewChannelThread (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId) (Evergreen.V307.Message.Message Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V307.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V307.Id.ThreadMessageId))
    | StopViewingChannel
