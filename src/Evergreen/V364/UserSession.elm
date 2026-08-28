module Evergreen.V364.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V364.Discord
import Evergreen.V364.FileStatus
import Evergreen.V364.Id
import Evergreen.V364.IdArray
import Evergreen.V364.Message
import Evergreen.V364.PersonName
import Evergreen.V364.Ports
import Evergreen.V364.SessionIdHash
import Evergreen.V364.UserAgent
import Evergreen.V364.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type UserOptionSection
    = UserOption_TwoFactorAuthentication
    | UserOption_Settings
    | UserOption_WhitelistedDomains
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
    | Subscribed Evergreen.V364.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V364.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V364.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V364.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.QuestionId SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V364.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V364.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V364.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V364.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V364.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V364.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V364.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V364.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V364.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V364.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V364.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V364.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V364.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V364.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V364.Id.ThreadMessageId
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
    { name : Evergreen.V364.PersonName.PersonName
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , color : Evergreen.V364.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V364.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V364.Id.Id messageId) (Evergreen.V364.Message.Message messageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId, Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId, Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId, Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V364.Id.Id Evergreen.V364.Id.UserId, Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId, Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId, Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId, Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId) (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V364.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V364.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
