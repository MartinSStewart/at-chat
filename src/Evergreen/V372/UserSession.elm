module Evergreen.V372.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V372.Discord
import Evergreen.V372.FileStatus
import Evergreen.V372.Id
import Evergreen.V372.IdArray
import Evergreen.V372.Message
import Evergreen.V372.PersonName
import Evergreen.V372.Ports
import Evergreen.V372.SessionIdHash
import Evergreen.V372.UserAgent
import Evergreen.V372.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId))
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
    | Subscribed Evergreen.V372.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V372.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.FileStatus.FileId) Evergreen.V372.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V372.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V372.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.QuestionId SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V372.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V372.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V372.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V372.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V372.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V372.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V372.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V372.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V372.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V372.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V372.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V372.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V372.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V372.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V372.Id.ThreadMessageId
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
    { name : Evergreen.V372.PersonName.PersonName
    , icon : Maybe Evergreen.V372.FileStatus.FileHash
    , color : Evergreen.V372.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V372.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V372.Id.Id messageId) (Evergreen.V372.Message.Message messageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId, Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId, Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId, Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId, Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId, Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId, Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId) (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V372.Id.ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V372.Id.ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)
