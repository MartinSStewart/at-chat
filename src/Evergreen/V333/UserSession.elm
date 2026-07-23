module Evergreen.V333.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V333.Discord
import Evergreen.V333.FileStatus
import Evergreen.V333.Id
import Evergreen.V333.Message
import Evergreen.V333.PersonName
import Evergreen.V333.Ports
import Evergreen.V333.SessionIdHash
import Evergreen.V333.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V333.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V333.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V333.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V333.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V333.PersonName.PersonName
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V333.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V333.Id.Id messageId) (Evergreen.V333.Message.Message messageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))))
    | ViewDmThread (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))))
    | ViewDiscordDm (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))))
    | ViewChannel (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))))
    | ViewChannelThread (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId) (Evergreen.V333.Message.Message Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V333.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V333.Id.ThreadMessageId))
    | StopViewingChannel
