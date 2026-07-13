module Evergreen.V318.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V318.Discord
import Evergreen.V318.FileStatus
import Evergreen.V318.Id
import Evergreen.V318.Message
import Evergreen.V318.PersonName
import Evergreen.V318.Ports
import Evergreen.V318.SessionIdHash
import Evergreen.V318.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V318.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V318.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V318.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V318.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V318.PersonName.PersonName
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute ))
    , userAgent : Evergreen.V318.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V318.Id.Id messageId) (Evergreen.V318.Message.Message messageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))))
    | ViewDmThread (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))))
    | ViewDiscordDm (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))))
    | ViewChannel (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))))
    | ViewChannelThread (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId) (Evergreen.V318.Message.Message Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V318.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V318.Id.ThreadMessageId))
    | StopViewingChannel
