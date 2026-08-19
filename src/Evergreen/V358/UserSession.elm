module Evergreen.V358.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V358.Discord
import Evergreen.V358.FileStatus
import Evergreen.V358.Id
import Evergreen.V358.Message
import Evergreen.V358.PersonName
import Evergreen.V358.Ports
import Evergreen.V358.SessionIdHash
import Evergreen.V358.UserAgent
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type UserOptionSection
    = UserOption_TwoFactorAuthentication
    | UserOption_Settings
    | UserOption_WhitelistedDomains
    | UserOption_Discord
    | UserOption_ConnectedDevices
    | UserOption_Debug


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V358.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V358.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V358.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V358.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V358.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V358.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V358.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V358.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V358.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V358.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V358.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V358.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V358.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V358.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V358.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V358.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V358.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V358.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V358.Id.ThreadMessageId
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
    { name : Evergreen.V358.PersonName.PersonName
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V358.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V358.Id.Id messageId) (Evergreen.V358.Message.Message messageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId, Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId, Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId, Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V358.Id.Id Evergreen.V358.Id.UserId, Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId, Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId, Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId, Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId) (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V358.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V358.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
