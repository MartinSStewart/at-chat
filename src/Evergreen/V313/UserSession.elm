module Evergreen.V313.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V313.Discord
import Evergreen.V313.FileStatus
import Evergreen.V313.Id
import Evergreen.V313.Message
import Evergreen.V313.PersonName
import Evergreen.V313.Ports
import Evergreen.V313.SessionIdHash
import Evergreen.V313.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V313.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V313.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V313.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V313.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V313.PersonName.PersonName
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute ))
    , userAgent : Evergreen.V313.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V313.Id.Id messageId) (Evergreen.V313.Message.Message messageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))))
    | ViewDmThread (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))))
    | ViewDiscordDm (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))))
    | ViewChannel (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))))
    | ViewChannelThread (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId) (Evergreen.V313.Message.Message Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V313.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V313.Id.ThreadMessageId))
    | StopViewingChannel
