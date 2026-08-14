module Evergreen.V352.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V352.Discord
import Evergreen.V352.FileStatus
import Evergreen.V352.Id
import Evergreen.V352.Message
import Evergreen.V352.PersonName
import Evergreen.V352.Ports
import Evergreen.V352.SessionIdHash
import Evergreen.V352.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V352.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V352.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V352.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V352.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V352.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V352.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V352.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V352.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V352.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V352.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V352.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V352.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V352.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V352.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V352.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V352.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V352.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V352.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V352.Id.ThreadMessageId
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
    { name : Evergreen.V352.PersonName.PersonName
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V352.UserAgent.UserAgent
    }


type SetViewing_ToBeFilledInByBackend a
    = SetViewing_EmptyPlaceholder
    | SetViewing_FilledInByBackend a
    | SetViewing_NothingToFillIn


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V352.Id.Id messageId) (Evergreen.V352.Message.Message messageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId, Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId, Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId, Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V352.Id.Id Evergreen.V352.Id.UserId, Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId, Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId, Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId, Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId) (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (SetViewing_ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V352.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (SetViewing_ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V352.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (SetViewing_ToBeFilledInByBackend UnreadOverviewData)
