module Evergreen.V316.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V316.Discord
import Evergreen.V316.FileStatus
import Evergreen.V316.Id
import Evergreen.V316.Message
import Evergreen.V316.PersonName
import Evergreen.V316.Ports
import Evergreen.V316.SessionIdHash
import Evergreen.V316.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V316.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V316.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V316.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V316.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V316.PersonName.PersonName
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute ))
    , userAgent : Evergreen.V316.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V316.Id.Id messageId) (Evergreen.V316.Message.Message messageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))))
    | ViewDmThread (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))))
    | ViewDiscordDm (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))))
    | ViewChannel (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))))
    | ViewChannelThread (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId) (Evergreen.V316.Message.Message Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V316.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V316.Id.ThreadMessageId))
    | StopViewingChannel
