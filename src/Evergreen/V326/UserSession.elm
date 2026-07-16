module Evergreen.V326.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V326.Discord
import Evergreen.V326.FileStatus
import Evergreen.V326.Id
import Evergreen.V326.Message
import Evergreen.V326.PersonName
import Evergreen.V326.Ports
import Evergreen.V326.SessionIdHash
import Evergreen.V326.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V326.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V326.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V326.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V326.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V326.PersonName.PersonName
    , icon : Maybe Evergreen.V326.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute ))
    , userAgent : Evergreen.V326.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V326.Id.Id messageId) (Evergreen.V326.Message.Message messageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))))
    | ViewDmThread (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))))
    | ViewDiscordDm (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))))
    | ViewChannel (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))))
    | ViewChannelThread (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId) (Evergreen.V326.Message.Message Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V326.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V326.Id.ThreadMessageId))
    | StopViewingChannel
