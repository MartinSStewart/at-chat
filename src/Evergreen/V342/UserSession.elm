module Evergreen.V342.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V342.Discord
import Evergreen.V342.FileStatus
import Evergreen.V342.Id
import Evergreen.V342.Message
import Evergreen.V342.PersonName
import Evergreen.V342.Ports
import Evergreen.V342.SessionIdHash
import Evergreen.V342.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V342.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V342.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V342.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V342.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V342.PersonName.PersonName
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V342.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V342.Id.Id messageId) (Evergreen.V342.Message.Message messageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId, Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId, Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId, Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V342.Id.Id Evergreen.V342.Id.UserId, Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId, Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId, Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId, Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))))
    | ViewDmThread (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))))
    | ViewDiscordDm (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))))
    | ViewChannel (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))))
    | ViewChannelThread (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId) (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V342.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V342.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
