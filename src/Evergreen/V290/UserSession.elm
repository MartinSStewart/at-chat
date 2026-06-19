module Evergreen.V290.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V290.Discord
import Evergreen.V290.FileStatus
import Evergreen.V290.Id
import Evergreen.V290.Message
import Evergreen.V290.PersonName
import Evergreen.V290.Ports
import Evergreen.V290.SessionIdHash
import Evergreen.V290.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V290.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V290.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute )
    , userAgent : Evergreen.V290.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V290.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V290.PersonName.PersonName
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.ThreadRoute )
    , userAgent : Evergreen.V290.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V290.Id.Id messageId) (Evergreen.V290.Message.Message messageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))))
    | ViewDmThread (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ThreadMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))))
    | ViewDiscordDm (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))))
    | ViewChannel (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))))
    | ViewChannelThread (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId) (Evergreen.V290.Message.Message Evergreen.V290.Id.ThreadMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V290.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V290.Id.ThreadMessageId))
    | StopViewingChannel
