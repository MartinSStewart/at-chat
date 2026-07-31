module Evergreen.V341.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V341.Discord
import Evergreen.V341.FileStatus
import Evergreen.V341.Id
import Evergreen.V341.Message
import Evergreen.V341.PersonName
import Evergreen.V341.Ports
import Evergreen.V341.SessionIdHash
import Evergreen.V341.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V341.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V341.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V341.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V341.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V341.PersonName.PersonName
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V341.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V341.Id.Id messageId) (Evergreen.V341.Message.Message messageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId, Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId, Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId, Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V341.Id.Id Evergreen.V341.Id.UserId, Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId, Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId, Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId, Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))))
    | ViewDmThread (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))))
    | ViewDiscordDm (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))))
    | ViewChannel (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))))
    | ViewChannelThread (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId) (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V341.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V341.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
