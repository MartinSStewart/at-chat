module Evergreen.V347.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V347.Discord
import Evergreen.V347.FileStatus
import Evergreen.V347.Id
import Evergreen.V347.Message
import Evergreen.V347.PersonName
import Evergreen.V347.Ports
import Evergreen.V347.SessionIdHash
import Evergreen.V347.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V347.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V347.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V347.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V347.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V347.PersonName.PersonName
    , icon : Maybe Evergreen.V347.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V347.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V347.Id.Id messageId) (Evergreen.V347.Message.Message messageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId, Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId, Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId, Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ThreadMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V347.Id.Id Evergreen.V347.Id.UserId, Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ThreadMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId, Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId, Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId, Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ThreadMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))))
    | ViewDmThread (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ThreadMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))))
    | ViewDiscordDm (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))))
    | ViewChannel (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))))
    | ViewChannelThread (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ThreadMessageId) (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V347.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V347.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
