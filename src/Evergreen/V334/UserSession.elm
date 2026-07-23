module Evergreen.V334.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V334.Discord
import Evergreen.V334.FileStatus
import Evergreen.V334.Id
import Evergreen.V334.Message
import Evergreen.V334.PersonName
import Evergreen.V334.Ports
import Evergreen.V334.SessionIdHash
import Evergreen.V334.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V334.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V334.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V334.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V334.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V334.PersonName.PersonName
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V334.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V334.Id.Id messageId) (Evergreen.V334.Message.Message messageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))))
    | ViewDmThread (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ThreadMessageId) (Evergreen.V334.Message.Message Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))))
    | ViewDiscordDm (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))))
    | ViewChannel (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))))
    | ViewChannelThread (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ThreadMessageId) (Evergreen.V334.Message.Message Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V334.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V334.Id.ThreadMessageId))
    | StopViewingChannel
