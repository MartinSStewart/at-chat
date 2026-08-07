module Evergreen.V346.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V346.Discord
import Evergreen.V346.FileStatus
import Evergreen.V346.Id
import Evergreen.V346.Message
import Evergreen.V346.PersonName
import Evergreen.V346.Ports
import Evergreen.V346.SessionIdHash
import Evergreen.V346.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V346.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V346.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V346.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V346.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V346.PersonName.PersonName
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V346.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V346.Id.Id messageId) (Evergreen.V346.Message.Message messageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId, Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId, Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId, Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V346.Id.Id Evergreen.V346.Id.UserId, Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId, Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId, Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId, Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))))
    | ViewDmThread (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))))
    | ViewDiscordDm (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))))
    | ViewChannel (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))))
    | ViewChannelThread (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId) (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V346.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V346.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
