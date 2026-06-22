module Evergreen.V294.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V294.Discord
import Evergreen.V294.FileStatus
import Evergreen.V294.Id
import Evergreen.V294.Message
import Evergreen.V294.PersonName
import Evergreen.V294.Ports
import Evergreen.V294.SessionIdHash
import Evergreen.V294.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V294.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V294.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute )
    , userAgent : Evergreen.V294.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V294.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V294.PersonName.PersonName
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.ThreadRoute )
    , userAgent : Evergreen.V294.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V294.Id.Id messageId) (Evergreen.V294.Message.Message messageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))))
    | ViewDmThread (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ThreadMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))))
    | ViewDiscordDm (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))))
    | ViewChannel (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))))
    | ViewChannelThread (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId) (Evergreen.V294.Message.Message Evergreen.V294.Id.ThreadMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V294.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V294.Id.ThreadMessageId))
    | StopViewingChannel
