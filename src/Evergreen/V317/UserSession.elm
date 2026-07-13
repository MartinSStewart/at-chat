module Evergreen.V317.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V317.Discord
import Evergreen.V317.FileStatus
import Evergreen.V317.Id
import Evergreen.V317.Message
import Evergreen.V317.PersonName
import Evergreen.V317.Ports
import Evergreen.V317.SessionIdHash
import Evergreen.V317.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V317.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V317.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V317.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V317.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V317.PersonName.PersonName
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute ))
    , userAgent : Evergreen.V317.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V317.Id.Id messageId) (Evergreen.V317.Message.Message messageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))))
    | ViewDmThread (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))))
    | ViewDiscordDm (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))))
    | ViewChannel (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))))
    | ViewChannelThread (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId) (Evergreen.V317.Message.Message Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V317.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V317.Id.ThreadMessageId))
    | StopViewingChannel
