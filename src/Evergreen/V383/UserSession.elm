module Evergreen.V383.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V383.Discord
import Evergreen.V383.FileStatus
import Evergreen.V383.Id
import Evergreen.V383.IdArray
import Evergreen.V383.Message
import Evergreen.V383.PersonName
import Evergreen.V383.Ports
import Evergreen.V383.SessionIdHash
import Evergreen.V383.UserAgent
import Evergreen.V383.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId))
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
    | Subscribed Evergreen.V383.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V383.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId) Evergreen.V383.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V383.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V383.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.QuestionId SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V383.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V383.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V383.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V383.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V383.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V383.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V383.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V383.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V383.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V383.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V383.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V383.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V383.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V383.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V383.Id.ThreadMessageId
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
    { name : Evergreen.V383.PersonName.PersonName
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , color : Evergreen.V383.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V383.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V383.Id.Id messageId) (Evergreen.V383.Message.Message messageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId, Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId, Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId, Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId, Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId, Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId, Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId) (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V383.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V383.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
