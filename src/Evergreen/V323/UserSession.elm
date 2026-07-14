module Evergreen.V323.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V323.Discord
import Evergreen.V323.FileStatus
import Evergreen.V323.Id
import Evergreen.V323.Message
import Evergreen.V323.PersonName
import Evergreen.V323.Ports
import Evergreen.V323.SessionIdHash
import Evergreen.V323.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V323.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V323.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V323.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V323.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V323.PersonName.PersonName
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ))
    , userAgent : Evergreen.V323.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V323.Id.Id messageId) (Evergreen.V323.Message.Message messageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))))
    | ViewDmThread (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))))
    | ViewDiscordDm (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))))
    | ViewChannel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))))
    | ViewChannelThread (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V323.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V323.Id.ThreadMessageId))
    | StopViewingChannel
