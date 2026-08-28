module Evergreen.V363.UserSession exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V363.Discord
import Evergreen.V363.FileStatus
import Evergreen.V363.Id
import Evergreen.V363.Message
import Evergreen.V363.PersonName
import Evergreen.V363.Ports
import Evergreen.V363.SessionIdHash
import Evergreen.V363.UserAgent
import Evergreen.V363.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId))
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
    | Subscribed Evergreen.V363.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V363.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.FileStatus.FileId) Evergreen.V363.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V363.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V363.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Array.Array SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V363.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V363.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V363.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V363.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V363.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V363.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V363.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V363.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V363.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V363.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V363.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V363.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V363.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V363.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V363.Id.ThreadMessageId
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
    { name : Evergreen.V363.PersonName.PersonName
    , icon : Maybe Evergreen.V363.FileStatus.FileHash
    , color : Evergreen.V363.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V363.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V363.Id.Id messageId) (Evergreen.V363.Message.Message messageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId, Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId, Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId, Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V363.Id.Id Evergreen.V363.Id.UserId, Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId, Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId, Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId, Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId) (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V363.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V363.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
