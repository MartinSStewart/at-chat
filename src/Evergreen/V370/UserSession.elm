module Evergreen.V370.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V370.Discord
import Evergreen.V370.FileStatus
import Evergreen.V370.Id
import Evergreen.V370.IdArray
import Evergreen.V370.Message
import Evergreen.V370.PersonName
import Evergreen.V370.Ports
import Evergreen.V370.SessionIdHash
import Evergreen.V370.UserAgent
import Evergreen.V370.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId))
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
    | Subscribed Evergreen.V370.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V370.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V370.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V370.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.QuestionId SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V370.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V370.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V370.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V370.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V370.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V370.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V370.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V370.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V370.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V370.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V370.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V370.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V370.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V370.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V370.Id.ThreadMessageId
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
    { name : Evergreen.V370.PersonName.PersonName
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , color : Evergreen.V370.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V370.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V370.Id.Id messageId) (Evergreen.V370.Message.Message messageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId, Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId, Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId, Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId, Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId, Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId, Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId) (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V370.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V370.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
