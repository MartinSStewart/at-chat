module Evergreen.V319.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V319.Discord
import Evergreen.V319.FileStatus
import Evergreen.V319.Id
import Evergreen.V319.Message
import Evergreen.V319.PersonName
import Evergreen.V319.Ports
import Evergreen.V319.SessionIdHash
import Evergreen.V319.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V319.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V319.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V319.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V319.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V319.PersonName.PersonName
    , icon : Maybe Evergreen.V319.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute ))
    , userAgent : Evergreen.V319.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V319.Id.Id messageId) (Evergreen.V319.Message.Message messageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))))
    | ViewDmThread (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))))
    | ViewDiscordDm (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))))
    | ViewChannel (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))))
    | ViewChannelThread (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId) (Evergreen.V319.Message.Message Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V319.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V319.Id.ThreadMessageId))
    | StopViewingChannel
