module Evergreen.V298.UserSession exposing (..)

import Effect.Http
import Effect.Time
import Evergreen.V298.Discord
import Evergreen.V298.FileStatus
import Evergreen.V298.Id
import Evergreen.V298.Message
import Evergreen.V298.PersonName
import Evergreen.V298.Ports
import Evergreen.V298.SessionIdHash
import Evergreen.V298.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V298.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V298.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V298.Id.Id Evergreen.V298.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute )
    , userAgent : Evergreen.V298.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V298.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V298.PersonName.PersonName
    , icon : Maybe Evergreen.V298.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.ThreadRoute )
    , userAgent : Evergreen.V298.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V298.Id.Id messageId) (Evergreen.V298.Message.Message messageId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))))
    | ViewDmThread (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))))
    | ViewDiscordDm (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))))
    | ViewChannel (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))))
    | ViewChannelThread (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId) (Evergreen.V298.Message.Message Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V298.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V298.Id.ThreadMessageId))
    | StopViewingChannel
