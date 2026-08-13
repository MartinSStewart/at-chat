module Evergreen.V351.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V351.Discord
import Evergreen.V351.FileStatus
import Evergreen.V351.Id
import Evergreen.V351.Message
import Evergreen.V351.PersonName
import Evergreen.V351.Ports
import Evergreen.V351.SessionIdHash
import Evergreen.V351.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V351.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V351.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V351.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V351.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V351.PersonName.PersonName
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V351.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V351.Id.Id messageId) (Evergreen.V351.Message.Message messageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId, Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId, Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId, Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V351.Id.Id Evergreen.V351.Id.UserId, Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId, Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId, Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId, Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))))
    | ViewDmThread (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))))
    | ViewDiscordDm (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))))
    | ViewChannel (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))))
    | ViewChannelThread (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId) (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V351.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V351.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
