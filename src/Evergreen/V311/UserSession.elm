module Evergreen.V311.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V311.Discord
import Evergreen.V311.FileStatus
import Evergreen.V311.Id
import Evergreen.V311.Message
import Evergreen.V311.PersonName
import Evergreen.V311.Ports
import Evergreen.V311.SessionIdHash
import Evergreen.V311.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V311.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V311.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V311.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V311.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V311.PersonName.PersonName
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute ))
    , userAgent : Evergreen.V311.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V311.Id.Id messageId) (Evergreen.V311.Message.Message messageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))))
    | ViewDmThread (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))))
    | ViewDiscordDm (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))))
    | ViewChannel (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))))
    | ViewChannelThread (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId) (Evergreen.V311.Message.Message Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V311.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V311.Id.ThreadMessageId))
    | StopViewingChannel
