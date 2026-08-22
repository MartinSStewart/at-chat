module Evergreen.V360.UserSession exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V360.Discord
import Evergreen.V360.FileStatus
import Evergreen.V360.Id
import Evergreen.V360.Message
import Evergreen.V360.PersonName
import Evergreen.V360.Ports
import Evergreen.V360.SessionIdHash
import Evergreen.V360.UserAgent
import Evergreen.V360.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId))
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
    | Subscribed Evergreen.V360.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V360.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.FileStatus.FileId) Evergreen.V360.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V360.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V360.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Array.Array SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V360.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V360.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V360.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V360.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V360.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V360.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V360.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V360.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V360.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V360.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V360.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V360.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V360.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V360.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V360.Id.ThreadMessageId
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
    { name : Evergreen.V360.PersonName.PersonName
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , color : Evergreen.V360.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V360.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V360.Id.Id messageId) (Evergreen.V360.Message.Message messageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId, Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId, Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId, Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V360.Id.Id Evergreen.V360.Id.UserId, Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId, Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId, Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId, Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId) (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V360.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V360.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
