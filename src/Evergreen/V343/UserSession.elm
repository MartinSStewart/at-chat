module Evergreen.V343.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V343.Discord
import Evergreen.V343.FileStatus
import Evergreen.V343.Id
import Evergreen.V343.Message
import Evergreen.V343.PersonName
import Evergreen.V343.Ports
import Evergreen.V343.SessionIdHash
import Evergreen.V343.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V343.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V343.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V343.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V343.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V343.PersonName.PersonName
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V343.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V343.Id.Id messageId) (Evergreen.V343.Message.Message messageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId, Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId, Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId, Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V343.Id.Id Evergreen.V343.Id.UserId, Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId, Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId, Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId, Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))))
    | ViewDmThread (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))))
    | ViewDiscordDm (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))))
    | ViewChannel (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))))
    | ViewChannelThread (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId) (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V343.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V343.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
