module Evergreen.V339.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V339.Discord
import Evergreen.V339.FileStatus
import Evergreen.V339.Id
import Evergreen.V339.Message
import Evergreen.V339.PersonName
import Evergreen.V339.Ports
import Evergreen.V339.SessionIdHash
import Evergreen.V339.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V339.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V339.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V339.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V339.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V339.PersonName.PersonName
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V339.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V339.Id.Id messageId) (Evergreen.V339.Message.Message messageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))))
    | ViewDmThread (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))))
    | ViewDiscordDm (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))))
    | ViewChannel (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))))
    | ViewChannelThread (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId) (Evergreen.V339.Message.Message Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V339.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V339.Id.ThreadMessageId))
    | StopViewingChannel
