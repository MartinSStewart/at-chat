module Evergreen.V348.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V348.Discord
import Evergreen.V348.FileStatus
import Evergreen.V348.Id
import Evergreen.V348.Message
import Evergreen.V348.PersonName
import Evergreen.V348.Ports
import Evergreen.V348.SessionIdHash
import Evergreen.V348.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V348.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V348.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V348.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V348.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V348.PersonName.PersonName
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V348.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V348.Id.Id messageId) (Evergreen.V348.Message.Message messageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId, Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId, Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId, Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V348.Id.Id Evergreen.V348.Id.UserId, Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId, Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId, Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId, Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))))
    | ViewDmThread (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))))
    | ViewDiscordDm (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))))
    | ViewChannel (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))))
    | ViewChannelThread (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId) (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V348.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V348.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
