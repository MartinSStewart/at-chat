module Evergreen.V345.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V345.Discord
import Evergreen.V345.FileStatus
import Evergreen.V345.Id
import Evergreen.V345.Message
import Evergreen.V345.PersonName
import Evergreen.V345.Ports
import Evergreen.V345.SessionIdHash
import Evergreen.V345.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V345.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V345.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V345.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V345.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V345.PersonName.PersonName
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V345.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V345.Id.Id messageId) (Evergreen.V345.Message.Message messageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId, Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId, Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId, Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V345.Id.Id Evergreen.V345.Id.UserId, Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId, Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId, Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId, Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))))
    | ViewDmThread (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))))
    | ViewDiscordDm (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))))
    | ViewChannel (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))))
    | ViewChannelThread (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId) (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V345.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V345.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
