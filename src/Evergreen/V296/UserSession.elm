module Evergreen.V296.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V296.Discord
import Evergreen.V296.FileStatus
import Evergreen.V296.Id
import Evergreen.V296.Message
import Evergreen.V296.PersonName
import Evergreen.V296.Ports
import Evergreen.V296.SessionIdHash
import Evergreen.V296.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V296.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V296.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute )
    , userAgent : Evergreen.V296.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V296.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V296.PersonName.PersonName
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.ThreadRoute )
    , userAgent : Evergreen.V296.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V296.Id.Id messageId) (Evergreen.V296.Message.Message messageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))))
    | ViewDmThread (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))))
    | ViewDiscordDm (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))))
    | ViewChannel (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))))
    | ViewChannelThread (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId) (Evergreen.V296.Message.Message Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V296.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V296.Id.ThreadMessageId))
    | StopViewingChannel
