module Evergreen.V354.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V354.Discord
import Evergreen.V354.FileStatus
import Evergreen.V354.Id
import Evergreen.V354.Message
import Evergreen.V354.PersonName
import Evergreen.V354.Ports
import Evergreen.V354.SessionIdHash
import Evergreen.V354.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V354.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V354.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V354.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V354.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V354.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V354.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V354.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V354.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V354.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V354.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V354.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V354.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V354.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V354.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V354.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V354.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V354.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V354.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V354.Id.ThreadMessageId
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
    { name : Evergreen.V354.PersonName.PersonName
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V354.UserAgent.UserAgent
    }


type SetViewing_ToBeFilledInByBackend a
    = SetViewing_EmptyPlaceholder
    | SetViewing_FilledInByBackend a
    | SetViewing_NothingToFillIn


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V354.Id.Id messageId) (Evergreen.V354.Message.Message messageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId, Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId, Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId, Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V354.Id.Id Evergreen.V354.Id.UserId, Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId, Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId, Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId, Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (SetViewing_ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId) (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (SetViewing_ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V354.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (SetViewing_ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V354.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (SetViewing_ToBeFilledInByBackend UnreadOverviewData)
