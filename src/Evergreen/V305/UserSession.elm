module Evergreen.V305.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V305.Discord
import Evergreen.V305.FileStatus
import Evergreen.V305.Id
import Evergreen.V305.Message
import Evergreen.V305.PersonName
import Evergreen.V305.Ports
import Evergreen.V305.SessionIdHash
import Evergreen.V305.UserAgent
import SeqDict


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V305.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V305.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V305.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V305.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V305.PersonName.PersonName
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId (Maybe ( Evergreen.V305.Id.AnyGuildOrDmId, Evergreen.V305.Id.ThreadRoute ))
    , userAgent : Evergreen.V305.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V305.Id.Id messageId) (Evergreen.V305.Message.Message messageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))))
    | ViewDmThread (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ThreadMessageId) (Evergreen.V305.Message.Message Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))))
    | ViewDiscordDm (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))))
    | ViewChannel (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))))
    | ViewChannelThread (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ThreadMessageId) (Evergreen.V305.Message.Message Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V305.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V305.Id.ThreadMessageId))
    | StopViewingChannel
