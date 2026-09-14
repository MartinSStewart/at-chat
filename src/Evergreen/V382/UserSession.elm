module Evergreen.V382.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V382.Discord
import Evergreen.V382.FileStatus
import Evergreen.V382.Id
import Evergreen.V382.IdArray
import Evergreen.V382.Message
import Evergreen.V382.PersonName
import Evergreen.V382.Ports
import Evergreen.V382.SessionIdHash
import Evergreen.V382.UserAgent
import Evergreen.V382.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId))
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
    | Subscribed Evergreen.V382.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V382.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V382.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V382.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.QuestionId SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V382.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V382.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V382.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V382.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V382.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V382.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V382.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V382.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V382.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V382.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V382.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V382.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V382.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V382.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V382.Id.ThreadMessageId
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
    { name : Evergreen.V382.PersonName.PersonName
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , color : Evergreen.V382.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V382.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V382.Id.Id messageId) (Evergreen.V382.Message.Message messageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId, Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId, Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId, Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId, Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId, Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId, Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId) (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V382.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V382.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
