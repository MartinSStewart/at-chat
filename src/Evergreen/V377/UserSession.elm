module Evergreen.V377.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V377.Discord
import Evergreen.V377.FileStatus
import Evergreen.V377.Id
import Evergreen.V377.IdArray
import Evergreen.V377.Message
import Evergreen.V377.PersonName
import Evergreen.V377.Ports
import Evergreen.V377.SessionIdHash
import Evergreen.V377.UserAgent
import Evergreen.V377.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type UserOptionSection
    = UserOption_TwoFactorAuthentication
    | UserOption_Settings
    | UserOption_WhitelistedDomains
    | UserOption_E2ee
    | UserOption_Discord
    | UserOption_ConnectedDevices
    | UserOption_Debug


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V377.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V377.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.FileStatus.FileId) Evergreen.V377.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V377.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V377.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.QuestionId SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V377.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V377.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V377.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V377.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V377.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V377.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V377.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V377.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V377.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V377.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V377.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V377.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V377.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V377.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V377.Id.ThreadMessageId
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


type alias DiscordFrontendUser =
    { name : Evergreen.V377.PersonName.PersonName
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , color : Evergreen.V377.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V377.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V377.Id.Id messageId) (Evergreen.V377.Message.Message messageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId, Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId, Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId, Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId, Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId, Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId, Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId) (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V377.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V377.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
