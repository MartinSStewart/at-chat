module Evergreen.V349.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V349.Discord
import Evergreen.V349.FileStatus
import Evergreen.V349.Id
import Evergreen.V349.Message
import Evergreen.V349.PersonName
import Evergreen.V349.Ports
import Evergreen.V349.SessionIdHash
import Evergreen.V349.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V349.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V349.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V349.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V349.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V349.PersonName.PersonName
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V349.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V349.Id.Id messageId) (Evergreen.V349.Message.Message messageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId, Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId, Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId, Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V349.Id.Id Evergreen.V349.Id.UserId, Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId, Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId, Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId, Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))))
    | ViewDmThread (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))))
    | ViewDiscordDm (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))))
    | ViewChannel (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))))
    | ViewChannelThread (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId) (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V349.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V349.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
