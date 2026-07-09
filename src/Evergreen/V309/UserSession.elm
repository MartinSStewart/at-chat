module Evergreen.V309.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V309.Discord
import Evergreen.V309.FileStatus
import Evergreen.V309.Id
import Evergreen.V309.Message
import Evergreen.V309.PersonName
import Evergreen.V309.Ports
import Evergreen.V309.SessionIdHash
import Evergreen.V309.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V309.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V309.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V309.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V309.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V309.PersonName.PersonName
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute ))
    , userAgent : Evergreen.V309.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V309.Id.Id messageId) (Evergreen.V309.Message.Message messageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))))
    | ViewDmThread (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))))
    | ViewDiscordDm (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))))
    | ViewChannel (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))))
    | ViewChannelThread (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId) (Evergreen.V309.Message.Message Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V309.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V309.Id.ThreadMessageId))
    | StopViewingChannel
