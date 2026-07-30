module Evergreen.V340.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V340.Discord
import Evergreen.V340.FileStatus
import Evergreen.V340.Id
import Evergreen.V340.Message
import Evergreen.V340.PersonName
import Evergreen.V340.Ports
import Evergreen.V340.SessionIdHash
import Evergreen.V340.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V340.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V340.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V340.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V340.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V340.PersonName.PersonName
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V340.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V340.Id.Id messageId) (Evergreen.V340.Message.Message messageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId, Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId, Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))))
    | ViewDmThread (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))))
    | ViewDiscordDm (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))))
    | ViewChannel (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))))
    | ViewChannelThread (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId) (Evergreen.V340.Message.Message Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V340.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V340.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
