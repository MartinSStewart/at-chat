module Evergreen.V330.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V330.Discord
import Evergreen.V330.FileStatus
import Evergreen.V330.Id
import Evergreen.V330.Message
import Evergreen.V330.PersonName
import Evergreen.V330.Ports
import Evergreen.V330.SessionIdHash
import Evergreen.V330.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V330.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V330.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V330.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V330.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V330.PersonName.PersonName
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V330.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V330.Id.Id messageId) (Evergreen.V330.Message.Message messageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))))
    | ViewDmThread (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))))
    | ViewDiscordDm (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))))
    | ViewChannel (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))))
    | ViewChannelThread (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId) (Evergreen.V330.Message.Message Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V330.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V330.Id.ThreadMessageId))
    | StopViewingChannel
