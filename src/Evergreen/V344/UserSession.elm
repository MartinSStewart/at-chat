module Evergreen.V344.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V344.Discord
import Evergreen.V344.FileStatus
import Evergreen.V344.Id
import Evergreen.V344.Message
import Evergreen.V344.PersonName
import Evergreen.V344.Ports
import Evergreen.V344.SessionIdHash
import Evergreen.V344.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V344.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V344.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V344.Id.Id Evergreen.V344.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V344.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V344.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V344.PersonName.PersonName
    , icon : Maybe Evergreen.V344.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V344.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V344.Id.Id messageId) (Evergreen.V344.Message.Message messageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId, Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId, Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId, Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V344.Id.Id Evergreen.V344.Id.UserId, Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId, Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId, Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId, Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))))
    | ViewDmThread (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))))
    | ViewDiscordDm (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))))
    | ViewChannel (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))))
    | ViewChannelThread (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId) (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V344.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V344.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
