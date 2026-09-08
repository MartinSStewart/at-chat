module Evergreen.V373.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V373.Discord
import Evergreen.V373.FileStatus
import Evergreen.V373.Id
import Evergreen.V373.IdArray
import Evergreen.V373.Message
import Evergreen.V373.PersonName
import Evergreen.V373.Ports
import Evergreen.V373.SessionIdHash
import Evergreen.V373.UserAgent
import Evergreen.V373.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId))
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
    | Subscribed Evergreen.V373.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V373.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V373.Id.Id Evergreen.V373.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V373.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V373.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.QuestionId SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V373.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V373.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V373.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V373.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V373.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V373.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V373.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V373.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V373.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V373.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V373.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V373.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V373.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V373.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V373.Id.ThreadMessageId
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
    { name : Evergreen.V373.PersonName.PersonName
    , icon : Maybe Evergreen.V373.FileStatus.FileHash
    , color : Evergreen.V373.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V373.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V373.Id.Id messageId) (Evergreen.V373.Message.Message messageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId, Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId, Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId, Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId, Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId, Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId, Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId) (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V373.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V373.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
