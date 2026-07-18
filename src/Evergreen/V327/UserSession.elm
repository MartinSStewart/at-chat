module Evergreen.V327.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V327.Discord
import Evergreen.V327.FileStatus
import Evergreen.V327.Id
import Evergreen.V327.Message
import Evergreen.V327.PersonName
import Evergreen.V327.Ports
import Evergreen.V327.SessionIdHash
import Evergreen.V327.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V327.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V327.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V327.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V327.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V327.PersonName.PersonName
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute ))
    , userAgent : Evergreen.V327.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V327.Id.Id messageId) (Evergreen.V327.Message.Message messageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))))
    | ViewDmThread (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))))
    | ViewDiscordDm (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))))
    | ViewChannel (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))))
    | ViewChannelThread (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId) (Evergreen.V327.Message.Message Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V327.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V327.Id.ThreadMessageId))
    | StopViewingChannel
