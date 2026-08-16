module Evergreen.V353.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V353.Discord
import Evergreen.V353.FileStatus
import Evergreen.V353.Id
import Evergreen.V353.Message
import Evergreen.V353.PersonName
import Evergreen.V353.Ports
import Evergreen.V353.SessionIdHash
import Evergreen.V353.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V353.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V353.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V353.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V353.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V353.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V353.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V353.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V353.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V353.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V353.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V353.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V353.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V353.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V353.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V353.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V353.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V353.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V353.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V353.Id.ThreadMessageId
    }


type Viewing
    = Viewing_Dm Viewing_DmData
    | Viewing_DmThread Viewing_DmThreadData
    | Viewing_DiscordDm Viewing_DiscordDmData
    | Viewing_Channel Viewing_ChannelData
    | Viewing_ChannelThread Viewing_ChannelThreadData
    | Viewing_DiscordChannel Viewing_DiscordChannelData
    | Viewing_DiscordChannelThread Viewing_DiscordChannelThreadData
    | Viewing_None
    | Viewing_Overview


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V353.PersonName.PersonName
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V353.UserAgent.UserAgent
    }


type SetViewing_ToBeFilledInByBackend a
    = SetViewing_EmptyPlaceholder
    | SetViewing_FilledInByBackend a
    | SetViewing_NothingToFillIn


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V353.Id.Id messageId) (Evergreen.V353.Message.Message messageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId, Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId, Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId, Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V353.Id.Id Evergreen.V353.Id.UserId, Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId, Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId, Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId, Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId) (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (SetViewing_ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V353.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (SetViewing_ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V353.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (SetViewing_ToBeFilledInByBackend UnreadOverviewData)
